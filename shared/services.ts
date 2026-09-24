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
	/** A short LAN name served next to `<slug>.atlas.local`, e.g. `atlas.jurrejan.com`. One label
	 *  under `jurrejan.com`, so the NAS's `*.jurrejan.com` wildcard cert covers it (no new ACME cert). */
	host?: string;
}

export interface ServiceRegistry {
	version: number;
	services: ServiceDef[];
}

export const registry = registryData as ServiceRegistry;

export function getServices(): ServiceDef[] {
	return registry.services;
}
