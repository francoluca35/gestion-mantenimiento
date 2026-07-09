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

export class UpdateUsuarioDto {
	@IsOptional()
	@IsString()
	@MinLength(6)
	clave?: string;

	@IsOptional()
	@IsEmail()
	email?: string;

	@IsOptional()
	@IsAppUuid()
	sucursalId?: string | null;

	@IsOptional()
	@IsAppUuid()
	sectorId?: string | null;

	@IsOptional()
	@IsAppUuid()
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
