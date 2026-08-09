// @ts-check

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Synology Wiki',
  tagline: 'Internal Documentation Hub',
  url: 'https://your-domain.local',
  baseUrl: '/',
  onBrokenLinks: 'warn',
  onBrokenMarkdownLinks: 'warn',

  i18n: {
    defaultLocale: 'cs',
    locales: ['cs', 'en'],
    localeConfigs: {
      cs: {
        htmlLang: 'cs',
        label: 'Čeština',
      },
      en: {
        htmlLang: 'en',
        label: 'English',
      },
    },
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          routeBasePath: '/', // Serve docs at root URL
        },
        blog: false,
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      navbar: {
        title: 'Synology Wiki',
        items: [
          {
            type: 'doc',
            docId: 'index',
            position: 'left',
            label: 'Docs',
          },
          {
            type: 'localeDropdown',
            position: 'right',
          },
        ],
      },
      footer: {
        style: 'dark',
        copyright: `Copyright © ${new Date().getFullYear()} Synology Wiki.`,
      },
    }),
};

module.exports = config;
