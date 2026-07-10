import { IsEmail, IsOptional, MinLength } from 'class-validator';

export class UpdateProfileDto {
  @IsOptional()
  @IsEmail({}, { message: 'Ju lutem vendosni një email të vlefshëm.' })
  email?: string;

  @IsOptional()
  @MinLength(6, { message: 'Fjalëkalimi duhet të jetë së paku 6 karaktere.' })
  password?: string;
}
