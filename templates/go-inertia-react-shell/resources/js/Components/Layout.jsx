import React from 'react';
import { Head } from '@inertiajs/react';

export default function Layout({ title, children }) {
  return (
    <>
      <Head title={title} />
      <div className="min-h-screen flex flex-col">
        <nav className="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
          <div className="container flex h-14 items-center">
            <div className="flex gap-6 items-center">
              <a href="/" className="font-medium transition-colors hover:text-foreground/80">Home</a>
              <a href="/about" className="font-medium transition-colors hover:text-foreground/80">About</a>
              <a href="/contact" className="font-medium transition-colors hover:text-foreground/80">Contact</a>
            </div>
          </div>
        </nav>
        <main className="flex-1 p-8">{children}</main>
        <footer className="border-t py-6 md:py-0">
          <div className="container flex items-center justify-center md:h-16">
            <p className="text-center text-sm leading-loose text-muted-foreground">
              &copy; 2024 Inertia + Go + React App
            </p>
          </div>
        </footer>
      </div>
    </>
  );
}