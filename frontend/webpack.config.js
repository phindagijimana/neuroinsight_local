const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');

module.exports = (env, argv) => {
  const isProduction = argv.mode === 'production';

  return {
    mode: isProduction ? 'production' : 'development',
    entry: './src/main.jsx',
    output: {
      path: path.resolve(__dirname, 'dist'),
      filename: 'bundle.js',
    },
    module: {
      rules: [
        {
          test: /\.(js|jsx)$/,
          exclude: /node_modules/,
          use: {
            loader: 'babel-loader',
          },
        },
        {
          test: /\.css$/,
          use: ['style-loader', 'css-loader'],
        },
      ],
    },
    resolve: {
      extensions: ['.js', '.jsx'],
    },
    plugins: [
      new HtmlWebpackPlugin({
        template: './index.html',
      }),
    ],
    devServer: {
      port: 3000,
      host: '0.0.0.0',
      proxy: {
        '/api': {
          target: 'http://localhost:8006',
          changeOrigin: true,
          pathRewrite: { '^/api': '' }
        },
        '/jobs': 'http://localhost:8006',
        '/upload': 'http://localhost:8006',
        '/health': 'http://localhost:8006',
        '/docs': 'http://localhost:8006'
      },
      historyApiFallback: true,
      hot: true
    },
  };
};
