import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { Listing } from './types';

@Processor('listings-queue')
@Injectable()
export class ScraperProcessor extends WorkerHost {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {
    super();
  }

  async process(job: Job<Listing>): Promise<void> {
    const listing = job.data;
    console.log(`Processing listing from queue: ${listing.title} (${listing.price} EUR) in ${listing.city}`);

    // 1. Fetch all active alerts from database
    const activeAlerts = await this.prisma.alert.findMany({
      where: { isActive: true },
      include: { user: true },
    });

    for (const alert of activeAlerts) {
      if (this.isMatch(listing, alert)) {
        console.log(`Match! Alert "${alert.title}" matches listing "${listing.title}"`);

        // Check if notification already sent to avoid duplicate alerts
        const existingNotification = await this.prisma.notification.findFirst({
          where: {
            alertId: alert.id,
            url: listing.url,
          },
        });

        if (existingNotification) {
          console.log(`Notification already exists for Alert ID ${alert.id} and Listing ID ${listing.id}. Skipping.`);
          continue;
        }

        // 2. Create notification record in DB
        const notification = await this.prisma.notification.create({
          data: {
            userId: alert.userId,
            alertId: alert.id,
            title: `Njoftim i ri: ${listing.title}`,
            price: listing.price,
            city: listing.city,
            category: listing.category,
            url: listing.url,
            imageUrl: listing.imageUrl,
          },
        });

        // 3. Send Push Notification via Firebase (or logs it if FCM not fully configured)
        if (alert.user.fcmToken) {
          const body = `${listing.price} EUR - Ndodhet në ${listing.city}`;
          await this.notificationsService.sendPushNotification(
            alert.user.fcmToken,
            notification.title,
            body,
            {
              notificationId: notification.id,
              alertId: alert.id,
              url: listing.url,
            },
          );
        }
      }
    }
  }

  private isMatch(listing: Listing, alert: any): boolean {
    // 1. Match keyword (case-insensitive)
    if (alert.keyword) {
      const keywordLower = alert.keyword.toLowerCase().trim();
      const titleLower = listing.title.toLowerCase();
      if (!titleLower.includes(keywordLower)) {
        return false;
      }
    }

    // 2. Match minPrice
    if (alert.minPrice !== null && alert.minPrice !== undefined) {
      if (listing.price < alert.minPrice) {
        return false;
      }
    }

    // 3. Match maxPrice
    if (alert.maxPrice !== null && alert.maxPrice !== undefined) {
      if (listing.price > alert.maxPrice) {
        return false;
      }
    }

    // 4. Match city (case-insensitive)
    if (alert.city) {
      const cityLower = alert.city.toLowerCase().trim();
      const listingCityLower = listing.city.toLowerCase().trim();
      
      // Normalize to strip accents (e.g. Tiranë -> Tirane)
      const normalizedCity = cityLower.normalize('NFD').replace(/[\u0300-\u036f]/g, '');
      const normalizedListingCity = listingCityLower.normalize('NFD').replace(/[\u0300-\u036f]/g, '');

      if (!normalizedListingCity.includes(normalizedCity) && !normalizedCity.includes(normalizedListingCity)) {
        return false;
      }
    }

    // 5. Match category (case-insensitive)
    if (alert.category) {
      const catLower = alert.category.toLowerCase().trim();
      const listingCatLower = listing.category.toLowerCase().trim();
      if (!listingCatLower.includes(catLower) && !catLower.includes(listingCatLower)) {
        return false;
      }
    }

    return true;
  }
}
