#!/usr/bin/env bash

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <project-name>"
  exit 1
fi

echo "$1" | yarn create next-app --typescript --eslint
cd "$1"
yarn add \
  @typescript-eslint/eslint-plugin \
  eslint-config-prettier \
  tailwindcss postcss autoprefixer \
  clsx
yarn add --exact prettier

# Edit default files
cat <<EOF > pages/_app.tsx
import '../styles/globals.css';
import Head from 'next/head';
import type { AppProps } from 'next/app';

export default function App({ Component, pageProps }: AppProps) {
  return (
    <>
      <Head>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
      </Head>
      <Component {...pageProps} />
    </>
  );
}
EOF

cat <<EOF > pages/index.tsx
export default function Home() {
  return <h1 className="text-blue-600">Hello, world!</h1>;
}
EOF

# Rearrange structure
mkdir -p src/styles
mv pages src/pages
rm -r styles

# EditorConfig
cat <<EOF > .editorconfig
root = true

[*]
charset = utf-8
insert_final_newline = true
indent_size = 2
indent_style = space
max_line_length = 120
trim_trailing_whitespace = true
EOF

# .gitignore
cat <<EOF > .gitignore
/.next
/node_modules
env.local
env.*.local
EOF

# ESLint
cat <<EOF > .eslintrc.json
{
  "plugins": ["@typescript-eslint"],
  "extends": [
    "next/core-web-vitals",
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:@typescript-eslint/recommended-requiring-type-checking",
    "prettier"
  ],
  "parserOptions": {
    "project": "tsconfig.json"
  }
}
EOF

# Prettier
cat <<EOF > .prettierignore
/.next
/node_modules
EOF

cat <<EOF > .prettierrc.json
{
  "singleQuote": true,
  "trailingComma": "all"
}
EOF

awk '/"lint": /{print $0",";print "    \"style\": \"prettier --write .\"";next}1' package.json > package.json.tmp \
    && mv package.json.tmp package.json

# TailwindCSS
npx tailwindcss init -p

cat <<EOF > tailwind.config.js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOF

cat <<EOF > src/styles/globals.css
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF

# TypeScript
awk '/"strict": /{print;print "    \"noImplicitOverride\": true,\n    \"noUncheckedIndexedAccess\": true,";next}1' tsconfig.json > tsconfig.json.tmp \
    && mv tsconfig.json.tmp tsconfig.json

# Finishing touches
echo "" | yarn lint
yarn style
rm -rf .git
git init
git add .
git commit -m "Initial commit"

echo ""
echo "Done! 🎉"
echo "Now \`cd\` into \"./$1/\" and run \`yarn dev\` to start the development server."
