import { IsArray } from 'class-validator';

export class CompletarChecklistDto {
	@IsArray()
	items!: unknown[];
}
