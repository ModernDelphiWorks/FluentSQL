import type { SidebarsConfig } from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    {
      type: 'doc',
      id: 'intro',
      label: 'Documentation portal',
    },
    {
      type: 'category',
      label: 'Projetos',
      items: [{ type: 'link', label: 'FluentSQL', href: '/fluentsql/' }],
    },
  ],
  fluentsqlSidebar: [
    {
      type: 'category',
      label: 'FluentSQL',
      link: { type: 'doc', id: 'fluentsql/index' },
      items: [
        'fluentsql/introduction',
        {
          type: 'category',
          label: 'Primeiros passos',
          items: [
            'fluentsql/getting-started/installation',
            'fluentsql/getting-started/quickstart',
            'fluentsql/getting-started/documentation-ci',
          ],
        },
        {
          type: 'category',
          label: 'Manual de uso',
          items: [
            'fluentsql/guides/construir-select',
            'fluentsql/guides/dml-insert-update-delete',
            'fluentsql/guides/parametros-e-uniao',
            'fluentsql/guides/extensao-por-dialeto',
            'fluentsql/guides/ddl-create-table',
            'fluentsql/guides/ddl-drop-table',
            'fluentsql/guides/ddl-alter-table-add-column',
            'fluentsql/guides/ddl-alter-table-drop-column',
            'fluentsql/guides/ddl-alter-table-rename-column',
            'fluentsql/guides/ddl-create-index',
            'fluentsql/guides/ddl-truncate-table',
          ],
        },
        {
          type: 'category',
          label: 'Arquitetura',
          items: [
            'fluentsql/architecture/overview',
            'fluentsql/architecture/runtime-flow',
          ],
        },
        {
          type: 'category',
          label: 'Referência',
          items: ['fluentsql/reference/configuration', 'fluentsql/reference/api'],
        },
        {
          type: 'category',
          label: 'Testes e suporte',
          items: ['fluentsql/tests/overview', 'fluentsql/troubleshooting/common-errors'],
        },
      ],
    },
  ],
};

export default sidebars;
