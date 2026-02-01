import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  build: {
    rollupOptions: {
      input: path.resolve(__dirname, 'index.build.html'),
    },
    outDir: 'dist',
    emptyOutDir: true,
  },
  server: {
    port: 3000,
    host: true,
    strictPort: true,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ''),
      },
      // Proxy all other requests to backend
      '^/(jobs|upload|cleanup|health|reports|visualizations)': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      },
    },
  },
})

