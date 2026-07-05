import { SetMetadata } from '@nestjs/common';

export const DERECHO_KEY = 'derecho';
export const RequiereDerecho = (codigo: string) => SetMetadata(DERECHO_KEY, codigo);
