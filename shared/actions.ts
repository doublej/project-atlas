import registryData from './actions.json';

export interface ActionGroup {
	id: string;
	label: string;
}

export interface ActionApi {
	method: string;
	endpoint: string;
}

export interface ActionDef {
	id: string;
	label: string;
	group: string;
	icon: string;
	shortcut?: string;
	type: string;
	condition?: string[];
	dynamic?: string;
	consumers?: string[];
	api?: ActionApi;
	command?: string;
	value?: string;
}

export interface ActionRegistry {
	version: number;
	groups: ActionGroup[];
	actions: ActionDef[];
}

export const registry = registryData as ActionRegistry;

export interface ProjectLike {
	/** Only the primary host's projects carry this. Its absence is what hides every write action. */
	isLocal?: boolean;
	devCommand?: string;
	runner?: string;
	scripts?: Record<string, string>;
	hasJustfile?: boolean;
	justRecipes?: string[];
	deploy?: { platform: string; url?: string }[];
	beads?: { open: number; inProgress: number; closed: number };
	domains?: string[];
	umami?: { websiteIds: string[]; instance?: string };
	claudeSessions?: { lastAt: string; count: number; summary?: string };
}

function getField(project: ProjectLike, field: string): unknown {
	switch (field) {
		case 'isLocal': return project.isLocal;
		case 'devCommand': return project.devCommand;
		case 'runner': return project.runner;
		case 'scripts': return project.scripts;
		case 'hasJustfile': return project.hasJustfile;
		case 'justRecipes': return project.justRecipes;
		case 'deploy': return project.deploy;
		case 'beads': return project.beads;
		case 'domains': return project.domains;
		case 'umami': return project.umami?.websiteIds;
		case 'claudeSessions': return project.claudeSessions;
		default: return undefined;
	}
}

function meetsCondition(action: ActionDef, project: ProjectLike): boolean {
	if (!action.condition) return true;
	return action.condition.every((field) => {
		const val = getField(project, field);
		if (val == null) return false;
		if (Array.isArray(val)) return val.length > 0;
		if (typeof val === 'object') return Object.keys(val).length > 0;
		return Boolean(val);
	});
}

export function getActions(project: ProjectLike, consumer: string): ActionDef[] {
	return registry.actions.filter((a) => {
		if (a.consumers && !a.consumers.includes(consumer)) return false;
		if (a.dynamic) return false;
		return meetsCondition(a, project);
	});
}

export function getDynamicActions(
	actionId: string,
	project: ProjectLike
): { action: ActionDef; name: string; value?: string }[] {
	const template = registry.actions.find((a) => a.id === actionId);
	if (!template?.dynamic) return [];

	if (template.dynamic === 'scripts' && project.scripts) {
		return Object.keys(project.scripts).map((name) => ({
			action: template,
			name,
		}));
	}
	if (template.dynamic === 'justRecipes' && project.justRecipes) {
		return project.justRecipes.map((name) => ({
			action: template,
			name,
		}));
	}
	if (template.dynamic === 'deploy' && project.deploy) {
		return project.deploy
			.filter((d) => d.url)
			.map((d) => ({
				action: template,
				name: d.platform,
				value: d.url,
			}));
	}
	if (template.dynamic === 'domains' && project.domains) {
		return project.domains.map((domain) => ({
			action: template,
			name: domain,
			value: `https://${domain}`,
		}));
	}
	if (template.dynamic === 'umami' && project.umami?.instance) {
		return project.umami.websiteIds.map((websiteId) => ({
			action: template,
			name: websiteId.slice(0, 8),
			value: `${project.umami!.instance}/websites/${websiteId}`,
		}));
	}
	return [];
}

export function getGroupsForActions(actions: ActionDef[]): ActionGroup[] {
	const groupIds = new Set(actions.map((a) => a.group));
	return registry.groups.filter((g) => groupIds.has(g.id));
}

export function getActionsByGroup(
	actions: ActionDef[],
	groupId: string
): ActionDef[] {
	return actions.filter((a) => a.group === groupId);
}
