import { IsInt, IsOptional, Min } from 'class-validator';
import { IsAppUuid } from '../../../../common/decorators/is-app-uuid.decorator';

export class MoverUbicacionDto {
	@IsOptional()
	@IsAppUuid()
	parentId?: string | null;

	@IsOptional()
	@IsInt()
	@Min(0)
	orden?: number;
}
