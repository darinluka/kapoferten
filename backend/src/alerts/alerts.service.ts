import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateAlertDto } from './dto/create-alert.dto';
import { UpdateAlertDto } from './dto/update-alert.dto';

@Injectable()
export class AlertsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, dto: CreateAlertDto) {
    return this.prisma.alert.create({
      data: {
        userId,
        title: dto.title,
        keyword: dto.keyword,
        minPrice: dto.minPrice,
        maxPrice: dto.maxPrice,
        city: dto.city,
        category: dto.category,
      },
    });
  }

  async findAll(userId: string) {
    return this.prisma.alert.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(userId: string, id: string) {
    const alert = await this.prisma.alert.findFirst({
      where: { id, userId },
    });

    if (!alert) {
      throw new NotFoundException('Alerti nuk u gjet.');
    }

    return alert;
  }

  async update(userId: string, id: string, dto: UpdateAlertDto) {
    await this.findOne(userId, id); // verifies ownership

    return this.prisma.alert.update({
      where: { id },
      data: {
        title: dto.title,
        keyword: dto.keyword,
        minPrice: dto.minPrice,
        maxPrice: dto.maxPrice,
        city: dto.city,
        category: dto.category,
        isActive: dto.isActive,
      },
    });
  }

  async remove(userId: string, id: string) {
    await this.findOne(userId, id); // verifies ownership

    await this.prisma.alert.delete({
      where: { id },
    });

    return { success: true };
  }
}
