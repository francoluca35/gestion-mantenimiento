import { IsInt, IsOptional, IsUUID, Min } from 'class-validator';

export class MoverUbicacionDto {
	@IsOptional()
	@IsUUID()
	parentId?: string | null;

	@IsOptional()
	@IsInt()
	@Min(0)
	orden?: number;
}
