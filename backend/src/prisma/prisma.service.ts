import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  async onModuleInit() {
    // Connect to database on startup
    await this.$connect();
  }

  async onModuleDestroy() {
    // Disconnect on application shutdown
    await this.$disconnect();
  }
}
