// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import starlightLinksValidator from 'starlight-links-validator';
import starlightLlmsTxt from 'starlight-llms-txt';
import starlightImageZoom from 'starlight-image-zoom';
import starlightSiteGraph from 'starlight-site-graph';
import starlightContextualMenu from 'starlight-contextual-menu';

// https://astro.build/config
export default defineConfig({
	site: 'https://example.com/',
	integrations: [
		starlight({
			title: 'My Docs',
			social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/withastro/starlight' }],
			plugins: [
				starlightLinksValidator(),
				starlightLlmsTxt(),
				starlightImageZoom(),
				starlightSiteGraph(),
				starlightContextualMenu({
					actions: ['copy', 'view', 'chatgpt', 'claude']
				}),
			],
			sidebar: [
				{
					label: 'Guides',
					items: [
						// Each item here is one entry in the navigation menu.
						{ label: 'Example Guide', slug: 'guides/example' },
					],
				},
				{
					label: 'Reference',
					autogenerate: { directory: 'reference' },
				},
			],
		}),
	],
});
