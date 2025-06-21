import React from 'react';
import Layout from '../Components/Layout';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
import { Button } from '../components/ui/button';

export default function Home({ title, message }) {
  return (
    <Layout title={title}>
      <div className="container max-w-4xl mx-auto">
        <Card>
          <CardHeader>
            <CardTitle className="text-4xl">{title}</CardTitle>
            <CardDescription className="text-lg">{message}</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex gap-4">
              <Button asChild>
                <a href="/about">About</a>
              </Button>
              <Button variant="outline" asChild>
                <a href="/contact">Contact</a>
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    </Layout>
  );
}