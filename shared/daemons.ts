import registryData from './daemons.json';

export interface DaemonLogs {
	stdout?: string;
	stderr?: string;
}

export interface DaemonDef {
	label: string;
	name: string;
	port?: number;
	project?: string | null;
	plist?: string;
	logs?: DaemonLogs;
	selfManaged?: boolean;
}

export interface DaemonRegistry {
	version: number;
	daemons: DaemonDef[];
}

export const registry = registryData as DaemonRegistry;

export function getDaemons(): DaemonDef[] {
	return registry.daemons;
}

export function getDaemonByLabel(label: string): DaemonDef | undefined {
	return registry.daemons.find((d) => d.label === label);
}
