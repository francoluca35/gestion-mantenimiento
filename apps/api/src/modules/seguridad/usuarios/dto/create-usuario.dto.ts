import {
	IsBoolean,
	IsEmail,
	IsEnum,
	IsOptional,
	IsString,
	MinLength,
} from 'class-validator';
import { IsAppUuid } from '../../../../common/decorators/is-app-uuid.decorator';
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
	@IsAppUuid()
	sucursalId?: string;

	@IsOptional()
	@IsAppUuid()
	sectorId?: string;

	@IsOptional()
	@IsAppUuid()
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
