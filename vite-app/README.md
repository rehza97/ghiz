# Vite + React + Shadcn UI Project

A modern React application built with Vite, featuring:

- **Vite** - Next generation frontend tooling
- **React 19** - UI library
- **TypeScript** - Type safety
- **Shadcn UI** - Beautiful component library
- **Tailwind CSS** - Utility-first CSS framework
- **Zod** - TypeScript-first schema validation
- **React Hook Form** - Performant forms with easy validation
- **TanStack Query (React Query)** - Powerful data synchronization
- **Firebase** - Backend services (Realtime Database, Auth, Firestore)
- **Zitadel** - Identity and access management (optional)

## Getting Started

### Prerequisites

- Node.js 18+ and npm
- Firebase project (optional, for Firebase features)

### Installation

1. Install dependencies:
```bash
npm install
```

2. Set up Firebase (optional):
   - Create a `.env` file in the root directory
   - Copy the example from `.env.example`
   - Add your Firebase configuration values:
   ```env
   VITE_FIREBASE_API_KEY=your-api-key
   VITE_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
   VITE_FIREBASE_DATABASE_URL=https://your-project-default-rtdb.firebaseio.com
   VITE_FIREBASE_PROJECT_ID=your-project-id
   VITE_FIREBASE_STORAGE_BUCKET=your-project.appspot.com
   VITE_FIREBASE_MESSAGING_SENDER_ID=123456789
   VITE_FIREBASE_APP_ID=1:123456789:web:abcdef
   ```

3. Start the development server:
```bash
npm run dev
```

4. Open [http://localhost:5173](http://localhost:5173) in your browser

## Project Structure

```
vite-app/
├── src/
│   ├── components/
│   │   ├── ui/              # Shadcn UI components
│   │   ├── example-form.tsx
│   │   ├── example-query.tsx
│   │   └── firebase-status.tsx  # Firebase connection status
│   ├── lib/
│   │   ├── utils.ts         # Utility functions (cn helper)
│   │   ├── query-client.ts  # React Query configuration
│   │   └── firebase.ts      # Firebase initialization
│   ├── App.tsx
│   ├── main.tsx
│   └── index.css            # Tailwind CSS with Shadcn variables
├── components.json          # Shadcn UI configuration
├── tailwind.config.js       # Tailwind CSS configuration
├── vite.config.ts           # Vite configuration with path aliases
└── .env.example             # Environment variables template
```

## Features

### Form Validation with Zod + React Hook Form

The `ExampleForm` component demonstrates:
- Zod schema validation
- React Hook Form integration
- Error handling and display
- Type-safe form values

### Data Fetching with React Query

The `ExampleQuery` component demonstrates:
- TanStack Query setup
- Data fetching and caching
- Loading and error states
- Manual refetching

### Firebase Connection Status

The `FirebaseStatus` component displays:
- Real-time connection status for Realtime Database
- Authentication service status
- Firestore connection status
- Automatic status checks every 30 seconds
- Manual refresh capability

## Adding More Shadcn Components

To add more Shadcn UI components, you can use the CLI:

```bash
npx shadcn@latest add [component-name]
```

Or manually add components following the same pattern as the existing UI components.

## Zitadel Integration

Zitadel is included in the dependencies. To set it up:

1. Configure your Zitadel instance
2. Set up environment variables
3. Initialize the Zitadel client in your app

Example:
```typescript
import { Zitadel } from '@zitadel/react'

// Configure Zitadel
const zitadel = new Zitadel({
  // Your configuration
})
```

## Building for Production

```bash
npm run build
```

The built files will be in the `dist` directory.

## License

MIT
