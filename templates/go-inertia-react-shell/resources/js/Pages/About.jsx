import React from 'react';
import { Link } from '@inertiajs/react';
import Layout from '../Components/Layout';

export default function About({ title, content }) {
  return (
    <Layout title={title}>
      <div className="max-w-4xl mx-auto bg-white rounded-lg shadow-md p-8">
        <h1 className="text-4xl font-bold text-slate-800 mb-6">{title}</h1>
        <p className="text-lg text-gray-600 mb-8">{content}</p>
        <Link 
          href="/" 
          className="inline-block px-6 py-3 bg-slate-600 text-white font-medium rounded-lg hover:bg-slate-700 transition-colors"
        >
          Back to Home
        </Link>
      </div>
    </Layout>
  );
}