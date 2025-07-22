import { Link } from "@tanstack/react-router";
import { Button } from "./ui/button";

export default function LandingHeader() {
  return (
    <header className="bg-white/95 backdrop-blur-sm border-b border-gray-200 sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          <div className="flex items-center">
            <Link
              to="/"
              className="text-2xl font-bold text-gray-900"
            >
              Connix
            </Link>
          </div>

          <div className="flex items-center space-x-4">
            <Link to="/sign-in">
              <Button
                variant="ghost"
                className="text-gray-700 hover:text-gray-900"
              >
                Sign In
              </Button>
            </Link>
            <Link to="/sign-up">
              <Button className="bg-blue-600 hover:bg-blue-700 text-white">
                Sign Up
              </Button>
            </Link>
          </div>
        </div>
      </div>
    </header>
  );
}
