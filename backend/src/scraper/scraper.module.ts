import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { BullModule } from '@nestjs/bullmq';
import { ScraperService } from './scraper.service';
import { ScraperProcessor } from './scraper.processor';
import { ScraperScheduler } from './scraper.scheduler';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    HttpModule,
    NotificationsModule,
    BullModule.registerQueue({
      name: 'listings-queue',
    }),
  ],
  providers: [ScraperService, ScraperProcessor, ScraperScheduler],
  exports: [ScraperService],
})
export class ScraperModule {}
