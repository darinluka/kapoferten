import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards } from '@nestjs/common';
import { AlertsService } from './alerts.service';
import { CreateAlertDto } from './dto/create-alert.dto';
import { UpdateAlertDto } from './dto/update-alert.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { GetUser } from '../auth/get-user.decorator';

@Controller('alerts')
@UseGuards(JwtAuthGuard)
export class AlertsController {
  constructor(private readonly alertsService: AlertsService) {}

  @Post()
  create(@GetUser() user: { id: string }, @Body() createAlertDto: CreateAlertDto) {
    return this.alertsService.create(user.id, createAlertDto);
  }

  @Get()
  findAll(@GetUser() user: { id: string }) {
    return this.alertsService.findAll(user.id);
  }

  @Get(':id')
  findOne(@GetUser() user: { id: string }, @Param('id') id: string) {
    return this.alertsService.findOne(user.id, id);
  }

  @Patch(':id')
  update(
    @GetUser() user: { id: string },
    @Param('id') id: string,
    @Body() updateAlertDto: UpdateAlertDto,
  ) {
    return this.alertsService.update(user.id, id, updateAlertDto);
  }

  @Delete(':id')
  remove(@GetUser() user: { id: string }, @Param('id') id: string) {
    return this.alertsService.remove(user.id, id);
  }
}
