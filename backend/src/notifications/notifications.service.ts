import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { initializeApp, cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import * as fs from 'fs';

@Injectable()
export class NotificationsService {
  private fcmInitialized = false;

  constructor(private prisma: PrismaService) {
    this.initializeFirebase();
  }

  private initializeFirebase() {
    try {
      const credPath = process.env.FIREBASE_CREDENTIALS;
      if (credPath && fs.existsSync(credPath)) {
        const serviceAccount = JSON.parse(fs.readFileSync(credPath, 'utf8'));
        initializeApp({
          credential: cert(serviceAccount),
        });
        this.fcmInitialized = true;
        console.log('Firebase Cloud Messaging successfully initialized.');
      } else {
        console.warn(
          'Firebase credentials file not found or not configured. Running in MOCK FCM mode.',
        );
      }
    } catch (error) {
      console.error('Failed to initialize Firebase Admin SDK:', error.message);
    }
  }

  async sendPushNotification(fcmToken: string, title: string, body: string, data?: Record<string, string>) {
    if (!fcmToken) return;

    if (this.fcmInitialized) {
      try {
        await getMessaging().send({
          token: fcmToken,
          notification: {
            title,
            body,
          },
          data,
        });
        console.log(`Push notification sent successfully to token: ${fcmToken.substring(0, 15)}...`);
      } catch (error) {
        console.error('Error sending push notification via Firebase:', error.message);
      }
    } else {
      console.log('--- [MOCK FCM PUSH] ---');
      console.log(`To FCM Token: ${fcmToken.substring(0, 15)}...`);
      console.log(`Title: ${title}`);
      console.log(`Body: ${body}`);
      console.log('Data:', data);
      console.log('-----------------------');
    }
  }

  async findAll(userId: string) {
    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async markAsRead(userId: string, id: string) {
    const notification = await this.prisma.notification.findFirst({
      where: { id, userId },
    });

    if (!notification) {
      throw new NotFoundException('Njoftimi nuk u gjet.');
    }

    return this.prisma.notification.update({
      where: { id },
      data: { isRead: true },
    });
  }

  async markAllAsRead(userId: string) {
    await this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });
    return { success: true };
  }
}
