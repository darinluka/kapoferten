import { IsEmail, IsNotEmpty } from 'class-validator';

export class LoginDto {
  @IsEmail({}, { message: 'Ju lutem vendosni një email të vlefshëm.' })
  @IsNotEmpty({ message: 'Emaili është i kërkuar.' })
  email: string;

  @IsNotEmpty({ message: 'Fjalëkalimi është i kërkuar.' })
  password: string;
}
