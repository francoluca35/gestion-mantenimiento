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

export class UpdateUsuarioDto {
	@IsOptional()
	@IsString()
	@MinLength(6)
	clave?: string;

	@IsOptional()
	@IsEmail()
	email?: string;

	@IsOptional()
	@IsUUID()
	sucursalId?: string | null;

	@IsOptional()
	@IsUUID()
	perfilId?: string | null;

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
	montoMaximoOc?: string | null;

	@IsOptional()
	@IsBoolean()
	activo?: boolean;
}
