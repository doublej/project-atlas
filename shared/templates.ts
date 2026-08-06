import registryData from './templates.json';

export interface TemplateRegistry {
	version: number;
	/** Category folder name → ordered list of suggested `family/name` templates. */
	categories: Record<string, string[]>;
}

export const registry = registryData as TemplateRegistry;

/** Suggested templates for a category, in display order. Empty if the category has none. */
export function getCategoryTemplates(category: string): string[] {
	return registry.categories[category] ?? [];
}
