import {
	Body,
	Controller,
	Delete,
	Get,
	Param,
	ParseUUIDPipe,
	Patch,
	Post,
} from '@nestjs/common';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { RequiereDerecho } from '../../../common/decorators/requiere-derecho.decorator';
import type { AuthUser } from '../auth/auth.types';
import { CreateUsuarioDto } from './dto/create-usuario.dto';
import { UpdateUsuarioDto } from './dto/update-usuario.dto';
import { UsuariosService } from './usuarios.service';

@Controller('usuarios')
export class UsuariosController {
	constructor(private readonly usuariosService: UsuariosService) {}

	@Get()
	@RequiereDerecho('configuracion.usuarios.listar')
	findAll(@CurrentUser() user: AuthUser) {
		return this.usuariosService.findAll(user);
	}

	@Get(':id')
	@RequiereDerecho('configuracion.usuarios.listar')
	findOne(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
		return this.usuariosService.findOne(id, user);
	}

	@Post()
	@RequiereDerecho('configuracion.usuarios.agregar')
	create(@Body() dto: CreateUsuarioDto, @CurrentUser() user: AuthUser) {
		return this.usuariosService.create(dto, user);
	}

	@Patch(':id')
	@RequiereDerecho('configuracion.usuarios.modificar')
	update(
		@Param('id', ParseUUIDPipe) id: string,
		@Body() dto: UpdateUsuarioDto,
		@CurrentUser() user: AuthUser,
	) {
		return this.usuariosService.update(id, dto, user);
	}

	@Delete(':id')
	@RequiereDerecho('configuracion.usuarios.borrar')
	deactivate(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: AuthUser) {
		return this.usuariosService.deactivate(id, user);
	}
}
