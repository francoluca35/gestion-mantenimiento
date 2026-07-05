import { Controller, Get } from '@nestjs/common';
import { DerechosService } from './derechos.service';

@Controller('derechos')
export class DerechosController {
	constructor(private readonly derechosService: DerechosService) {}

	@Get('tree')
	getTree() {
		return this.derechosService.getTree();
	}
}
