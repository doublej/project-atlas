import registryData from './hosts.json';

/** Which machine a host is, and how atlas treats it. */
export type HostRole = 'primary' | 'satellite' | 'deploy';

export interface HostDef {
	/** Stable id — also the value of `Project.host`. */
	id: string;
	label: string;
	/**
	 * SSH alias, never an IP: every host on this LAN is DHCP with no reservations and
	 * the addresses have already drifted once. `null` marks the primary host, which is
	 * scanned in-process rather than over SSH.
	 */
	ssh: string | null;
	/** Scan root **on that host**. `~/` is expanded against the primary's `$HOME`. */
	root: string;
	os: 'darwin' | 'linux' | 'win32';
	role: HostRole;
	/** Interpreter that runs the scan agent. Pinned absolutely where a shell may shadow it. */
	node?: string;
	/** Where `atlas hosts sync` puts the scan-agent bundle on that host. */
	agent?: string;
	/**
	 * Skip git detection on this host.
	 *
	 * On Fractal the git probe is a single shell command that does not survive the Windows
	 * shell: it comes back `error` for 25 of 33 repos, and a confidently wrong "error" badge
	 * is worse than no badge. Ubuntu's plain bash handles it fine, so it keeps git — that
	 * host's dirty state is the whole point of a deploy-target twin. Cost is not the reason:
	 * git adds ~1.3s to Fractal's ~9s scan.
	 */
	skipGit?: boolean;
}

export interface HostRegistry {
	version: number;
	hosts: HostDef[];
}

export const registry = registryData as HostRegistry;

/** Expand a leading `~/` — only meaningful for the primary host's own root. */
export function expandHome(p: string): string {
	return p.startsWith('~/') ? `${process.env.HOME ?? ''}/${p.slice(2)}` : p;
}

export function getHosts(): HostDef[] {
	return registry.hosts;
}

export function getHostById(id: string): HostDef | undefined {
	return registry.hosts.find((h) => h.id === id);
}

/** Remote hosts — everything reachable only over SSH. */
export function getRemoteHosts(): HostDef[] {
	return registry.hosts.filter((h) => h.ssh !== null);
}

/**
 * The machine atlas runs on. Its root is the catalog root every write path is confined to,
 * and its id is the default `Project.host`.
 */
export function getPrimaryHost(): HostDef {
	const primary = registry.hosts.find((h) => h.ssh === null);
	if (!primary) throw new Error('hosts.json: no primary host (one entry must have ssh: null)');
	return { ...primary, root: expandHome(primary.root) };
}
