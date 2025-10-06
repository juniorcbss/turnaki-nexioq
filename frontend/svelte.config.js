import adapter from '@sveltejs/adapter-static';

const config = {
  kit: {
    adapter: adapter({ fallback: 'index.html', strict: false }),
    csrf: { checkOrigin: true }
  }
};

export default config;
