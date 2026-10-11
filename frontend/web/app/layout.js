import './globals.css';
import { AuthProvider } from '../../../frontend/shared/context/AuthContext';

export const metadata = {
  title: 'Adult Joke Bot',
  description: 'Tell me a joke and let\'s laugh together!'
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body className="bg-gray-50">
        <AuthProvider>
          <main className="flex-1">
            {children}
          </main>
        </AuthProvider>
      </body>
    </html>
  );
}
