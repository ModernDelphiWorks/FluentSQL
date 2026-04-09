import type { Config } from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'FluentSQL',
  tagline: 'Fluent API para SQL em Delphi e Lazarus',
  favicon: 'img/favicon.svg',

  // Static output at repository root for `deploy-docs.yml` (git add docs/)
  outDir: '../docs',

  url: 'https://moderndelphiworks.github.io',
  baseUrl: '/FluentSQL/',
  organizationName: 'ModernDelphiWorks',
  projectName: 'FluentSQL',

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  i18n: {
    defaultLocale: 'pt-BR',
    locales: ['pt-BR'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          routeBasePath: '/',
          editUrl: undefined,
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    navbar: {
      title: 'FluentSQL',
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Início',
        },
        {
          type: 'dropdown',
          label: 'Projetos',
          position: 'left',
          items: [{ to: '/fluentsql/', label: 'FluentSQL' }],
        },
      ],
    },
    footer: {
      style: 'dark',
      copyright: `© ${new Date().getFullYear()} FluentSQL — ModernDelphiWorks.`,
    },
    prism: {
      additionalLanguages: ['bash', 'json', 'powershell'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
