import React, { useState } from 'react';
import { useForm, Link } from '@inertiajs/react';
import Layout from '../Components/Layout';

export default function Contact({ title }) {
  const { data, setData, post, processing } = useForm({
    name: '',
    email: '',
    message: '',
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    post('/contact');
  };

  return (
    <Layout title={title}>
      <div className="container">
        <h1>{title}</h1>
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="name">Name:</label>
            <input
              type="text"
              id="name"
              value={data.name}
              onChange={e => setData('name', e.target.value)}
              required
            />
          </div>
          <div className="form-group">
            <label htmlFor="email">Email:</label>
            <input
              type="email"
              id="email"
              value={data.email}
              onChange={e => setData('email', e.target.value)}
              required
            />
          </div>
          <div className="form-group">
            <label htmlFor="message">Message:</label>
            <textarea
              id="message"
              value={data.message}
              onChange={e => setData('message', e.target.value)}
              rows="5"
              required
            />
          </div>
          <button type="submit" disabled={processing}>
            {processing ? 'Sending...' : 'Send Message'}
          </button>
        </form>
        <Link href="/" className="back-link">Back to Home</Link>
      </div>
    </Layout>
  );
}