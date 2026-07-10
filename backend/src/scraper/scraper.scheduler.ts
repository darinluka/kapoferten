import { Injectable, OnApplicationBootstrap } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { ScraperService } from './scraper.service';

@Injectable()
export class ScraperScheduler implements OnApplicationBootstrap {
  private intervalId: NodeJS.Timeout;

  constructor(
    @InjectQueue('listings-queue') private readonly listingsQueue: Queue,
    private readonly scraperService: ScraperService,
  ) {}

  onApplicationBootstrap() {
    // Initial execution after 5 seconds
    setTimeout(() => this.runScrapeTask(), 5000);

    // Run every 2 minutes
    this.intervalId = setInterval(() => {
      this.runScrapeTask();
    }, 120000);
  }

  async runScrapeTask() {
    console.log('--- Scraping Cycle Started ---');
    try {
      const listings = await this.scraperService.fetchAllListings();
      console.log(`Scraper found ${listings.length} listings. Enqueuing to Redis queue...`);

      for (const listing of listings) {
        // Push each listing as a separate job to BullMQ
        await this.listingsQueue.add('process-listing', listing, {
          removeOnComplete: true,
          removeOnFail: true,
        });
      }
      console.log('Successfully enqueued all listings to Redis.');
    } catch (error) {
      console.error('Error during scraping task execution:', error.message);
    }
    console.log('--- Scraping Cycle Finished ---');
  }
}
