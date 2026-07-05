import {
	IsBoolean,
	IsEmail,
	IsEnum,
	IsOptional,
	IsString,
	IsUUID,
	MinLength,
} from 'class-validator';
import { SupervisaSolicitudesOt } from '@prisma/client';

export class CreateUsuarioDto {
	@IsString()
	@MinLength(2)
	nombreUsuario!: string;

	@IsString()
	@MinLength(6)
	clave!: string;

	@IsOptional()
	@IsEmail()
	email?: string;

	@IsOptional()
	@IsUUID()
	sucursalId?: string;

	@IsOptional()
	@IsUUID()
	perfilId?: string;

	@IsOptional()
	@IsBoolean()
	esAdministrador?: boolean;

	@IsOptional()
	@IsBoolean()
	supervisaSucursales?: boolean;

	@IsOptional()
	@IsEnum(SupervisaSolicitudesOt)
	supervisaSolicitudesOt?: SupervisaSolicitudesOt;

	@IsOptional()
	@IsBoolean()
	supervisaSolicitudesOc?: boolean;

	@IsOptional()
	@IsString()
	montoMaximoOc?: string;
}
