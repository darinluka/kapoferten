import { IsEmail, IsNotEmpty, MinLength } from 'class-validator';

export class RegisterDto {
  @IsEmail({}, { message: 'Ju lutem vendosni një email të vlefshëm.' })
  @IsNotEmpty({ message: 'Emaili është i kërkuar.' })
  email: string;

  @IsNotEmpty({ message: 'Fjalëkalimi është i kërkuar.' })
  @MinLength(6, { message: 'Fjalëkalimi duhet të jetë së paku 6 karaktere.' })
  password: string;
}
