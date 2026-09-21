import registryData from './services.json';

/** A permanent local web UI that gets a `<slug>.atlas.local` hostname without being a project. */
export interface ServiceDef {
	slug: string;
	name: string;
	port: number;
	/** `daemons.json` label, when the service is a launchd daemon. */
	daemon?: string;
	/** Also publish `<slug>.atlas.remote` behind the shared password. Off unless set. */
	remote?: boolean;
}

export interface ServiceRegistry {
	version: number;
	services: ServiceDef[];
}

export const registry = registryData as ServiceRegistry;

export function getServices(): ServiceDef[] {
	return registry.services;
}
