import { Link, createFileRoute } from "@tanstack/react-router";
import { useCallback, useEffect, useRef, useState } from "react";
import { Button } from "../components/ui/button";
import { authClient } from "../lib/auth-client";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      {
        title: "Connix - The Future of Agent Orchestration",
      },
    ],
  }),
  component: HomePage,
});

function HomePage() {
  const [isAuthenticated, setIsAuthenticated] = useState<boolean | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const checkAuth = async () => {
      try {
        const session = await authClient.getSession();
        setIsAuthenticated(!!session.data?.user);
      } catch {
        setIsAuthenticated(false);
      } finally {
        setIsLoading(false);
      }
    };

    checkAuth();
  }, []);

  if (isLoading || isAuthenticated === null) {
    return (
      <div className="flex items-center justify-center h-screen bg-gradient-to-br from-slate-50 via-white to-blue-50 relative overflow-hidden">
        {/* Enhanced loading background */}
        <div className="absolute inset-0 opacity-30">
          <div className="absolute top-1/4 left-1/4 w-64 h-64 bg-gradient-to-r from-blue-400/20 to-purple-500/20 rounded-full blur-3xl animate-float-slow"></div>
          <div className="absolute bottom-1/4 right-1/4 w-48 h-48 bg-gradient-to-r from-purple-400/20 to-pink-500/20 rounded-full blur-3xl animate-float-slow animation-delay-1000"></div>
        </div>
        
        <div className="relative z-10 text-center">
          {/* Multi-layered spinner */}
          <div className="relative mb-6">
            <div className="w-16 h-16 rounded-full border-4 border-slate-200 border-t-blue-500 animate-spin"></div>
            <div className="absolute inset-0 w-16 h-16 rounded-full border-4 border-transparent border-r-purple-400 animate-spin animation-delay-150"></div>
            <div className="absolute inset-2 w-12 h-12 rounded-full border-2 border-transparent border-b-pink-400 animate-spin animation-delay-300"></div>
            <div className="absolute inset-4 w-8 h-8 rounded-full bg-gradient-to-r from-blue-500 to-purple-600 animate-pulse"></div>
          </div>
          
          {/* Loading text with typing effect */}
          <div className="text-slate-700 font-medium">
            <div className="flex items-center justify-center space-x-1">
              <span>Loading Connix</span>
              <div className="flex space-x-1">
                <div className="w-1 h-1 bg-blue-500 rounded-full animate-bounce"></div>
                <div className="w-1 h-1 bg-purple-500 rounded-full animate-bounce animation-delay-150"></div>
                <div className="w-1 h-1 bg-pink-500 rounded-full animate-bounce animation-delay-300"></div>
              </div>
            </div>
          </div>
          
          {/* Progress indicators */}
          <div className="mt-4 w-48 h-1 bg-slate-200 rounded-full overflow-hidden">
            <div className="h-full bg-gradient-to-r from-blue-500 to-purple-600 rounded-full animate-pulse" style={{width: '70%'}}></div>
          </div>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <ModernLandingPage />;
  }

  return <AuthenticatedDashboard />;
}

function ModernLandingPage() {
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 });
  const [scrollY, setScrollY] = useState(0);
  // Note: isVisible state removed for performance - lazy loading implemented via Intersection Observer
  const [animationsEnabled, setAnimationsEnabled] = useState(true);
  const [reducedMotion, setReducedMotion] = useState(false);
  const heroRef = useRef<HTMLElement>(null);
  const observerRef = useRef<IntersectionObserver | null>(null);
  const ticking = useRef(false);
  const mouseTicking = useRef(false);

  // Enhanced throttled mouse move with performance optimization
  const throttledMouseMove = useCallback(
    (e: MouseEvent) => {
      if (!mouseTicking.current && animationsEnabled && !reducedMotion) {
        requestAnimationFrame(() => {
          setMousePosition({ x: e.clientX, y: e.clientY });
          mouseTicking.current = false;
        });
        mouseTicking.current = true;
      }
    },
    [animationsEnabled, reducedMotion]
  );

  useEffect(() => {
    // Check for reduced motion preference
    const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
    setReducedMotion(mediaQuery.matches);
    
    const handleMediaChange = (e: MediaQueryListEvent) => {
      setReducedMotion(e.matches);
      setAnimationsEnabled(!e.matches);
    };
    
    mediaQuery.addEventListener('change', handleMediaChange);

    // Optimized scroll handler with throttling
    const handleScroll = () => {
      if (!ticking.current && animationsEnabled && !reducedMotion) {
        requestAnimationFrame(() => {
          setScrollY(window.scrollY);
          ticking.current = false;
        });
        ticking.current = true;
      }
    };

    // Only add expensive event listeners if animations are enabled
    if (animationsEnabled && !reducedMotion) {
      window.addEventListener('mousemove', throttledMouseMove, { passive: true });
      window.addEventListener('scroll', handleScroll, { passive: true });
    }
    
    // Enhanced Intersection Observer with performance optimizations
    observerRef.current = new IntersectionObserver(
      (entries) => {
        // Batch DOM updates
        const updates: Record<string, boolean> = {};
        entries.forEach((entry) => {
          if (entry.target.id) {
            updates[entry.target.id] = entry.isIntersecting;
          }
        });
        
        // Performance optimization: Removed state updates for better performance
      },
      { 
        threshold: [0, 0.1, 0.5], 
        rootMargin: '100px 0px',
      }
    );

    return () => {
      if (animationsEnabled && !reducedMotion) {
        window.removeEventListener('mousemove', throttledMouseMove);
        window.removeEventListener('scroll', handleScroll);
      }
      mediaQuery.removeEventListener('change', handleMediaChange);
      observerRef.current?.disconnect();
    };
  }, [throttledMouseMove, animationsEnabled, reducedMotion]);

  useEffect(() => {
    // Lazy observe animated elements with delay
    const timeoutId = setTimeout(() => {
      const elements = document.querySelectorAll('[data-animate]');
      elements.forEach(el => {
        if (observerRef.current) {
          observerRef.current.observe(el);
        }
      });
    }, 100); // Small delay to improve initial render performance
    
    return () => {
      clearTimeout(timeoutId);
      const elements = document.querySelectorAll('[data-animate]');
      elements.forEach(el => observerRef.current?.unobserve(el));
    };
  }, []);

  return (
    <div className="min-h-screen relative overflow-hidden">
      {/* Advanced Gradient Mesh Background */}
      <div className="fixed inset-0 z-0">
        <div className="absolute inset-0 bg-gradient-to-br from-slate-50 via-white to-blue-50"></div>
        <div className="absolute inset-0 opacity-40">
          <div className="absolute top-0 left-0 w-full h-full" style={{
            background: `
              radial-gradient(ellipse 800px 600px at 10% 20%, rgba(59, 130, 246, 0.15) 0%, transparent 70%),
              radial-gradient(ellipse 600px 800px at 90% 80%, rgba(147, 51, 234, 0.12) 0%, transparent 70%),
              radial-gradient(ellipse 400px 400px at 50% 50%, rgba(236, 72, 153, 0.08) 0%, transparent 60%),
              radial-gradient(ellipse 1200px 400px at 30% 70%, rgba(16, 185, 129, 0.1) 0%, transparent 80%),
              radial-gradient(ellipse 500px 600px at 70% 30%, rgba(245, 101, 101, 0.08) 0%, transparent 70%)
            `
          }}></div>
        </div>
        {/* Animated Mesh Overlay */}
        <div className="absolute inset-0 opacity-30">
          <div className="w-full h-full animate-gradient-x" style={{
            background: `
              linear-gradient(45deg, 
                transparent 0%, 
                rgba(59, 130, 246, 0.05) 25%, 
                transparent 50%, 
                rgba(147, 51, 234, 0.05) 75%, 
                transparent 100%
              )
            `,
            backgroundSize: '400% 400%'
          }}></div>
        </div>
      </div>

      {/* Enhanced Navigation */}
      <nav className={`fixed top-0 left-0 right-0 z-50 transition-all duration-500 ${
        scrollY > 50 
          ? 'backdrop-blur-xl bg-white/80 border-b border-white/30 shadow-lg' 
          : 'backdrop-blur-md bg-white/60 border-b border-white/10'
      }`}>
        <div className="max-w-7xl mx-auto px-6">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center space-x-4 group">
              <div className="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center transition-all duration-300 group-hover:scale-110 group-hover:rotate-12">
                <span className="text-white font-bold text-sm">C</span>
              </div>
              <span className="text-xl font-bold bg-gradient-to-r from-slate-900 to-slate-600 bg-clip-text text-transparent group-hover:from-blue-600 group-hover:to-purple-600 transition-all duration-300">
                Connix
              </span>
            </div>
            <div className="hidden md:flex items-center space-x-8">
              <a href="#features" className="relative text-slate-600 hover:text-slate-900 transition-all duration-300 group">
                Features
                <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-gradient-to-r from-blue-500 to-purple-600 group-hover:w-full transition-all duration-300"></span>
              </a>
              <a href="#docs" className="relative text-slate-600 hover:text-slate-900 transition-all duration-300 group">
                Docs
                <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-gradient-to-r from-blue-500 to-purple-600 group-hover:w-full transition-all duration-300"></span>
              </a>
              <a href="#pricing" className="relative text-slate-600 hover:text-slate-900 transition-all duration-300 group">
                Pricing
                <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-gradient-to-r from-blue-500 to-purple-600 group-hover:w-full transition-all duration-300"></span>
              </a>
              <Link to="/sign-in">
                <Button variant="ghost" className="text-slate-600 hover:text-slate-900 hover:bg-slate-100/50 transition-all duration-300">
                  Sign In
                </Button>
              </Link>
              <Link to="/sign-up">
                <Button className="bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700 text-white rounded-full px-6 shadow-lg hover:shadow-xl hover:shadow-blue-500/25 transition-all duration-300 hover:scale-105 group relative overflow-hidden">
                  <span className="relative z-10">Get Started</span>
                  <div className="absolute inset-0 bg-gradient-to-r from-white/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </nav>

      {/* Optimized Background Elements with Performance Controls */}
      {animationsEnabled && !reducedMotion && (
        <div className="fixed inset-0 overflow-hidden pointer-events-none z-10" style={{ contain: 'layout style paint' }}>
          {/* Optimized Floating Gradient Orbs */}
          <div 
            className="absolute top-1/4 -left-64 w-96 h-96 rounded-full blur-3xl animate-float-slow transform-gpu"
            style={{ 
              transform: `translate3d(0, ${scrollY * 0.05}px, 0)`,
              background: `radial-gradient(ellipse at 40% 40%, rgba(59, 130, 246, 0.3) 0%, transparent 70%)`,
              willChange: 'transform'
            }}
          ></div>
          <div 
            className="absolute top-3/4 -right-64 w-80 h-80 rounded-full blur-3xl animate-float-slow animation-delay-3000 transform-gpu"
            style={{ 
              transform: `translate3d(0, ${scrollY * -0.08}px, 0)`,
              background: `radial-gradient(ellipse at 30% 70%, rgba(236, 72, 153, 0.25) 0%, transparent 70%)`,
              willChange: 'transform'
            }}
          ></div>
          <div 
            className="absolute top-1/2 left-1/2 w-72 h-72 rounded-full blur-3xl animate-pulse-gentle transform-gpu"
            style={{ 
              transform: `translate3d(-50%, -50%, 0) translateY(${scrollY * 0.03}px)`,
              background: `radial-gradient(ellipse at 50% 50%, rgba(16, 185, 129, 0.2) 0%, transparent 70%)`,
              willChange: 'transform'
            }}
          ></div>
          
          {/* Optimized Floating Elements - Reduced count and complexity */}
          {[...Array(12)].map((_, i) => {
            const elementTypes = [
              { size: 'w-2 h-2', gradient: 'from-blue-400 to-blue-500' },
              { size: 'w-3 h-3', gradient: 'from-purple-400 to-purple-500' },
              { size: 'w-2 h-2', gradient: 'from-green-400 to-green-500' }
            ];
            const element = elementTypes[i % elementTypes.length];
            return (
              <div
                key={i}
                className="absolute opacity-20 transform-gpu"
                style={{
                  left: `${15 + (i * 8)}%`,
                  top: `${25 + (i * 5)}%`,
                  transform: `translate3d(0, ${scrollY * (0.01 + i * 0.005)}px, 0)`,
                  willChange: 'transform',
                  contain: 'layout style paint'
                }}
              >
                <div className={`${element.size} bg-gradient-to-br ${element.gradient} rounded-full animate-gentle-float`} 
                     style={{ animationDelay: `${i * 0.3}s` }} />
              </div>
            );
          })}
          
          {/* Simplified Grid Pattern */}
          <div className="absolute inset-0 opacity-5" style={{ contain: 'layout style paint' }}>
            <div className="w-full h-full transform-gpu" style={{
              backgroundImage: `linear-gradient(90deg, rgba(59, 130, 246, 0.3) 1px, transparent 1px), linear-gradient(0deg, rgba(59, 130, 246, 0.3) 1px, transparent 1px)`,
              backgroundSize: '80px 80px',
              transform: `translate3d(0, ${scrollY * 0.05}px, 0)`,
              willChange: 'transform'
            }}></div>
          </div>

          {/* Optimized Particle System - Reduced count */}
          {[...Array(8)].map((_, i) => (
            <div
              key={`particle-${i}`}
              className="absolute w-1 h-1 bg-white rounded-full opacity-30 animate-gentle-float transform-gpu"
              style={{
                left: `${20 + i * 10}%`,
                top: `${30 + i * 8}%`,
                animationDelay: `${i * 0.5}s`,
                transform: `translate3d(0, ${scrollY * 0.02}px, 0)`,
                willChange: 'transform',
                contain: 'layout style paint'
              }}
            />
          ))}
        </div>
      )}

      {/* Optimized Mouse Follower - Only show if animations enabled */}
      {animationsEnabled && !reducedMotion && (
        <>
          <div 
            className="fixed w-64 h-64 pointer-events-none z-20 transition-all duration-500 ease-out opacity-30 transform-gpu"
            style={{
              left: mousePosition.x - 128,
              top: mousePosition.y - 128,
              background: `radial-gradient(circle at 50% 50%, rgba(59, 130, 246, 0.2) 0%, transparent 70%)`,
              filter: 'blur(40px)',
              transform: 'translate3d(0, 0, 0)',
              willChange: 'transform',
              contain: 'layout style paint'
            }}
          />
          <div 
            className="fixed w-4 h-4 pointer-events-none z-30 transition-all duration-100 ease-out opacity-60 transform-gpu"
            style={{
              left: mousePosition.x - 8,
              top: mousePosition.y - 8,
              background: 'radial-gradient(circle, rgba(255, 255, 255, 0.6) 0%, transparent 70%)',
              borderRadius: '50%',
              transform: 'translate3d(0, 0, 0)',
              willChange: 'transform'
            }}
          />
        </>
      )}

      {/* Enhanced Hero Section with 3D Effects */}
      <section ref={heroRef} className="relative pt-32 pb-20 px-6 z-30">
        <div className="max-w-6xl mx-auto text-center">
          <div className="inline-flex items-center px-6 py-3 bg-gradient-to-r from-blue-500/15 to-purple-500/15 backdrop-blur-xl rounded-full border border-blue-200/60 mb-8 animate-fade-in-up shadow-lg hover:shadow-xl hover:scale-105 transition-all duration-500 group">
            <span className="w-3 h-3 bg-gradient-to-r from-green-400 to-emerald-500 rounded-full mr-3 animate-pulse shadow-lg shadow-green-400/50 group-hover:shadow-green-400/70"></span>
            <span className="text-sm font-semibold text-slate-800 group-hover:text-slate-900 transition-colors duration-300">Now in Public Beta</span>
            <div className="ml-2 w-1 h-1 bg-blue-400 rounded-full opacity-60 animate-ping"></div>
          </div>
          
          <h1 className="text-5xl md:text-7xl lg:text-8xl font-black mb-8 tracking-tight animate-fade-in-up animation-delay-200 transform-gpu">
            <span className="block text-slate-900 mb-2 hover:scale-105 transition-transform duration-500 cursor-default" 
                  style={{ 
                    textShadow: '0 4px 20px rgba(0,0,0,0.1)',
                    transform: `perspective(1000px) rotateX(${scrollY * 0.01}deg)`
                  }}>The Future of</span>
            <span className="block bg-gradient-to-r from-blue-600 via-purple-600 via-pink-600 to-cyan-500 bg-clip-text text-transparent animate-gradient-x hover:scale-105 transition-transform duration-500 cursor-default"
                  style={{ 
                    backgroundSize: '300% 300%',
                    textShadow: '0 0 40px rgba(59, 130, 246, 0.3)',
                    transform: `perspective(1000px) rotateX(${scrollY * -0.01}deg)`
                  }}>
              Agent Orchestration
            </span>
          </h1>
          
          <p className="text-xl md:text-2xl text-slate-600 mb-12 max-w-4xl mx-auto leading-relaxed animate-fade-in-up animation-delay-400">
            Open Source Container Use Platform, MCP, and Tooling powered by Nix for Agents. 
            <span className="block mt-2 text-lg text-slate-500">Declarative, reproducible, and portable container use.</span>
          </p>
          
          <div className="flex flex-col sm:flex-row gap-4 justify-center mb-16 animate-fade-in-up animation-delay-600">
            <Link to="/sign-up">
              <Button className="bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700 text-white text-lg px-8 py-4 rounded-2xl shadow-xl hover:shadow-2xl hover:scale-105 transition-all duration-300 group">
                <span className="flex items-center">
                  Start Building
                  <svg className="ml-2 w-5 h-5 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
                  </svg>
                </span>
              </Button>
            </Link>
            <Button variant="outline" className="text-slate-700 border-slate-300 hover:bg-slate-50 text-lg px-8 py-4 rounded-2xl backdrop-blur-sm">
              View Documentation
            </Button>
          </div>

          {/* Enhanced Hero Visual with 3D Perspective */}
          <div className="relative max-w-5xl mx-auto animate-fade-in-up animation-delay-800 transform-gpu group">
            <div className="relative bg-gradient-to-br from-white/90 to-slate-100/90 backdrop-blur-2xl rounded-3xl border border-white/60 shadow-2xl p-8 hover:shadow-3xl hover:scale-[1.02] transition-all duration-700"
                 style={{
                   transform: `perspective(1000px) rotateX(${scrollY * 0.005}deg) rotateY(${(mousePosition.x - (typeof window !== 'undefined' ? window.innerWidth : 1920)/2) * 0.01}deg)`,
                   boxShadow: '0 25px 50px rgba(0,0,0,0.1), 0 0 100px rgba(59, 130, 246, 0.1)'
                 }}>
              <div className="aspect-video bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 rounded-2xl overflow-hidden relative group-hover:shadow-2xl transition-shadow duration-500"
                   style={{
                     boxShadow: 'inset 0 2px 20px rgba(255,255,255,0.1), 0 10px 30px rgba(0,0,0,0.2)'
                   }}>
                {/* Terminal-like interface */}
                <div className="flex items-center justify-between p-4 bg-slate-800/90 border-b border-slate-700">
                  <div className="flex space-x-2">
                    <div className="w-3 h-3 bg-red-400 rounded-full"></div>
                    <div className="w-3 h-3 bg-yellow-400 rounded-full"></div>
                    <div className="w-3 h-3 bg-green-400 rounded-full"></div>
                  </div>
                  <span className="text-slate-400 text-sm font-mono">connix-orchestrator</span>
                </div>
                <div className="p-6 font-mono text-sm">
                  <div className="text-green-400 mb-2">$ connix deploy my-agent-network</div>
                  <div className="text-slate-400 mb-1">🚀 Deploying agent orchestration...</div>
                  <div className="text-slate-400 mb-1">📦 Building Nix containers...</div>
                  <div className="text-slate-400 mb-1">🔗 Connecting agent networks...</div>
                  <div className="text-blue-400 mb-2">✅ Deployment successful!</div>
                  <div className="text-green-400 animate-pulse">$ _</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Modern Bento Grid Features */}
      <section className="py-24 px-6 relative">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-black text-slate-900 mb-6">
              Everything starts with <span className="bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">"Con"</span>
            </h2>
            <p className="text-xl text-slate-600 max-w-3xl mx-auto">
              Nine powerful capabilities that revolutionize how you build, deploy, and manage AI agents.
            </p>
          </div>

          {/* Bento Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {/* Enhanced Large feature card with 3D effects */}
            <div className="lg:col-span-2 lg:row-span-2 group perspective-1000">
              <div className="h-full bg-gradient-to-br from-blue-500/15 to-purple-500/15 backdrop-blur-xl rounded-3xl border border-blue-200/60 p-8 hover:border-blue-300/80 transition-all duration-500 hover:scale-[1.02] hover:shadow-xl glass-ultra group-hover:bg-gradient-to-br group-hover:from-blue-500/20 group-hover:to-purple-500/20 transform-gpu"
                   style={{
                     transform: animationsEnabled && !reducedMotion ? `translate3d(0, ${scrollY * 0.01}px, 0)` : 'none',
                     willChange: animationsEnabled ? 'transform' : 'auto',
                     contain: 'layout style paint'
                   }}>
                <div className="flex items-center mb-6">
                  <div className="w-14 h-14 bg-gradient-to-br from-blue-500 via-cyan-500 to-purple-600 rounded-2xl flex items-center justify-center text-white text-2xl mr-4 group-hover:rotate-12 group-hover:scale-110 transition-all duration-500 shadow-lg group-hover:shadow-xl animate-magnetic-pulse">
                    🔗
                  </div>
                  <div>
                    <h3 className="text-2xl font-bold text-slate-900 mb-1">
                      <span className="text-blue-600">Con</span>nect Agents
                    </h3>
                    <p className="text-slate-600">Multi-agent orchestration</p>
                  </div>
                </div>
                <p className="text-slate-700 text-lg leading-relaxed mb-6">
                  Seamlessly integrate multiple agents for collaborative workflows. Build complex agent networks that work together intelligently.
                </p>
                <div className="bg-white/50 backdrop-blur-sm rounded-2xl p-4 border border-white/70">
                  <pre className="text-sm text-slate-700 overflow-hidden">
                    <code>{`agent_network:
  - agent_a: classification
  - agent_b: processing  
  - agent_c: response`}</code>
                  </pre>
                </div>
              </div>
            </div>

            {/* Enhanced Medium feature cards with 3D perspective */}
            <div className="lg:col-span-1 group perspective-1000">
              <div className="h-full bg-gradient-to-br from-green-500/15 to-cyan-500/15 backdrop-blur-xl rounded-3xl border border-green-200/60 p-6 hover:border-green-300/80 transition-all duration-500 hover:scale-[1.03] hover:shadow-xl glass-ultra group-hover:bg-gradient-to-br group-hover:from-green-500/20 group-hover:to-cyan-500/20 transform-gpu"
                   style={{
                     transform: animationsEnabled && !reducedMotion ? `translate3d(0, ${scrollY * 0.015}px, 0)` : 'none',
                     willChange: animationsEnabled ? 'transform' : 'auto',
                     contain: 'layout style paint'
                   }}>
                <div className="w-12 h-12 bg-gradient-to-br from-green-500 via-emerald-500 to-cyan-600 rounded-xl flex items-center justify-center text-white text-xl mb-4 group-hover:rotate-12 group-hover:scale-125 transition-all duration-500 shadow-lg group-hover:shadow-xl animate-gentle-float">
                  📦
                </div>
                <h3 className="text-xl font-bold text-slate-900 mb-2">
                  <span className="text-green-600">Con</span>tainerized
                </h3>
                <p className="text-slate-600 text-sm">Nix-powered containers for reproducible agent environments</p>
              </div>
            </div>

            <div className="lg:col-span-1 group perspective-1000">
              <div className="h-full bg-gradient-to-br from-purple-500/15 to-pink-500/15 backdrop-blur-xl rounded-3xl border border-purple-200/60 p-6 hover:border-purple-300/80 transition-all duration-500 hover:scale-[1.03] hover:shadow-xl glass-ultra group-hover:bg-gradient-to-br group-hover:from-purple-500/20 group-hover:to-pink-500/20 transform-gpu"
                   style={{
                     transform: animationsEnabled && !reducedMotion ? `translate3d(0, ${scrollY * 0.012}px, 0)` : 'none',
                     willChange: animationsEnabled ? 'transform' : 'auto',
                     contain: 'layout style paint'
                   }}>
                <div className="w-12 h-12 bg-gradient-to-br from-purple-500 via-fuchsia-500 to-pink-600 rounded-xl flex items-center justify-center text-white text-xl mb-4 group-hover:rotate-12 group-hover:scale-125 transition-all duration-500 shadow-lg group-hover:shadow-xl animate-gentle-float animation-delay-200">
                  🎯
                </div>
                <h3 className="text-xl font-bold text-slate-900 mb-2">
                  <span className="text-purple-600">Con</span>strain
                </h3>
                <p className="text-slate-600 text-sm">Enforce best practices and security constraints automatically</p>
              </div>
            </div>

            {/* Enhanced Wide feature card with advanced 3D effects */}
            <div className="lg:col-span-2 group perspective-1000">
              <div className="h-full bg-gradient-to-r from-orange-500/15 to-red-500/15 backdrop-blur-xl rounded-3xl border border-orange-200/60 p-6 hover:border-orange-300/80 transition-all duration-500 hover:scale-[1.02] hover:shadow-xl glass-ultra group-hover:bg-gradient-to-r group-hover:from-orange-500/20 group-hover:to-red-500/20 transform-gpu"
                   style={{
                     transform: animationsEnabled && !reducedMotion ? `translate3d(0, ${scrollY * 0.008}px, 0)` : 'none',
                     willChange: animationsEnabled ? 'transform' : 'auto',
                     contain: 'layout style paint'
                   }}>
                <div className="flex items-center justify-between">
                  <div className="flex items-center">
                    <div className="w-12 h-12 bg-gradient-to-br from-orange-500 via-amber-500 to-red-600 rounded-xl flex items-center justify-center text-white text-xl mr-4 group-hover:rotate-12 group-hover:scale-110 transition-all duration-500 shadow-lg group-hover:shadow-xl animate-orbital-3d">
                      🎮
                    </div>
                    <div>
                      <h3 className="text-xl font-bold text-slate-900">
                        <span className="text-orange-600">Con</span>trol from Anywhere
                      </h3>
                      <p className="text-slate-600 text-sm">Remote management and orchestration</p>
                    </div>
                  </div>
                  <div className="hidden sm:block text-4xl opacity-30 group-hover:opacity-60 group-hover:scale-110 group-hover:rotate-12 transition-all duration-500 animate-gentle-float animation-delay-400">🌍</div>
                </div>
              </div>
            </div>

            {/* Enhanced Additional feature cards with advanced 3D */}
            {[
              { icon: "👥", title: "Connect to Developers", desc: "Bridge AI agents and development teams", color: "cyan", gradient: "from-cyan-500 via-blue-500 to-cyan-600" },
              { icon: "🔄", title: "Consolidate Development", desc: "Unified platform for agent development", color: "pink", gradient: "from-pink-500 via-rose-500 to-pink-600" },
              { icon: "💬", title: "Converse with Agents", desc: "Natural language interaction", color: "indigo", gradient: "from-indigo-500 via-purple-500 to-indigo-600" },
              { icon: "🏗️", title: "Construct Projects", desc: "Build applications with agent assistance", color: "teal", gradient: "from-teal-500 via-emerald-500 to-teal-600" },
              { icon: "🛡️", title: "Contain Securely", desc: "Isolation and resource management", color: "yellow", gradient: "from-yellow-500 via-amber-500 to-yellow-600" }
            ].map((feature, i) => (
              <div key={i} className="group perspective-1000">
                <div className={`h-full bg-gradient-to-br from-${feature.color}-500/15 to-${feature.color}-600/15 backdrop-blur-xl rounded-3xl border border-${feature.color}-200/60 p-6 hover:border-${feature.color}-300/80 transition-all duration-500 hover:scale-[1.03] hover:shadow-xl glass-ultra group-hover:bg-gradient-to-br group-hover:from-${feature.color}-500/20 group-hover:to-${feature.color}-600/20 transform-gpu`}
                     style={{
                       transform: animationsEnabled && !reducedMotion ? `translate3d(0, ${scrollY * (0.01 + i * 0.002)}px, 0)` : 'none',
                       willChange: animationsEnabled ? 'transform' : 'auto',
                       contain: 'layout style paint',
                       animationDelay: `${i * 100}ms`
                     }}>
                  <div className={`w-12 h-12 bg-gradient-to-br ${feature.gradient} rounded-xl flex items-center justify-center text-white text-xl mb-4 group-hover:rotate-12 group-hover:scale-125 transition-all duration-500 shadow-lg group-hover:shadow-xl animate-perspective-float-3d`}
                       style={{ animationDelay: `${i * 200}ms` }}>
                    {feature.icon}
                  </div>
                  <h3 className="text-lg font-bold text-slate-900 mb-2">
                    <span className={`text-${feature.color}-600`}>Con</span>{feature.title.slice(3)}
                  </h3>
                  <p className="text-slate-600 text-sm">{feature.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
        
        {/* Testimonials Section */}
        <div className="max-w-6xl mx-auto mt-24 px-6" data-animate id="testimonials">
          <div className="text-center mb-12">
            <h3 className="text-3xl font-bold text-slate-900 mb-4 animate-fade-in-up">Loved by Developers</h3>
            <p className="text-slate-600 animate-fade-in-up animation-delay-200">See what the community is saying about Connix</p>
          </div>
          <div className="grid md:grid-cols-3 gap-6">
            {[
              { name: "Alex Chen", role: "Senior ML Engineer", company: "TechCorp", text: "Connix has revolutionized how we deploy our agent workflows. The Nix integration is game-changing.", avatar: "AC" },
              { name: "Maria Rodriguez", role: "DevOps Lead", company: "StartupXYZ", text: "The containerized approach makes our agent deployments incredibly reliable and reproducible.", avatar: "MR" },
              { name: "David Kim", role: "AI Researcher", company: "Research Lab", text: "Finally, a platform that understands the complexity of multi-agent orchestration.", avatar: "DK" }
            ].map((testimonial, i) => (
              <div key={i} className={`group animate-fade-in-up animation-delay-${400 + (i * 200)}`}>
                <div className="bg-white/80 backdrop-blur-sm rounded-2xl p-6 border border-white/50 hover:border-white/70 hover:bg-white/90 transition-all duration-300 hover:scale-105 hover:shadow-xl">
                  <div className="flex items-center mb-4">
                    <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-white font-bold text-sm mr-3">
                      {testimonial.avatar}
                    </div>
                    <div>
                      <div className="font-semibold text-slate-900">{testimonial.name}</div>
                      <div className="text-sm text-slate-600">{testimonial.role} at {testimonial.company}</div>
                    </div>
                  </div>
                  <p className="text-slate-700 text-sm leading-relaxed italic">"{testimonial.text}"</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="py-24 px-6 relative" data-animate id="cta">
        <div className="max-w-4xl mx-auto text-center">
          <div className="bg-gradient-to-br from-slate-900 to-slate-800 rounded-3xl p-12 relative overflow-hidden group hover:scale-[1.02] transition-all duration-500 transform-gpu"
               style={{
                 transform: animationsEnabled && !reducedMotion ? `translate3d(0, ${scrollY * 0.005}px, 0)` : 'none',
                 willChange: animationsEnabled ? 'transform' : 'auto',
                 contain: 'layout style paint'
               }}>
            {/* Optimized Background pattern */}
            <div className="absolute inset-0 opacity-10 group-hover:opacity-15 transition-opacity duration-500" style={{ contain: 'layout style paint' }}>
              <div className="absolute inset-0" style={{
                background: `radial-gradient(ellipse at 30% 30%, rgba(59, 130, 246, 0.3) 0%, transparent 60%), radial-gradient(ellipse at 70% 70%, rgba(147, 51, 234, 0.25) 0%, transparent 60%)`
              }}></div>
            </div>
            
            {/* Floating particles */}
            {[...Array(6)].map((_, i) => (
              <div 
                key={i} 
                className="absolute w-1 h-1 bg-white rounded-full opacity-30 animate-gentle-float"
                style={{
                  left: `${20 + i * 15}%`,
                  top: `${30 + i * 10}%`,
                  animationDelay: `${i * 0.5}s`
                }}
              ></div>
            ))}
            
            <div className="relative z-10">
              <h2 className="text-4xl md:text-5xl font-black text-white mb-6 animate-fade-in-up group-hover:scale-105 transition-transform duration-500">
                Ready to revolutionize your <span className="bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent hover:from-cyan-400 hover:to-pink-400 transition-all duration-700">agent development</span>?
              </h2>
              <p className="text-xl text-slate-300 mb-8 max-w-2xl mx-auto animate-fade-in-up animation-delay-200 group-hover:text-slate-200 transition-colors duration-300">
                Join thousands of developers building the future of AI with declarative, reproducible agent orchestration.
              </p>
              <div className="flex flex-col sm:flex-row gap-4 justify-center animate-fade-in-up animation-delay-400">
                <Link to="/sign-up">
                  <Button className="bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700 text-white text-lg px-8 py-4 rounded-2xl shadow-xl hover:shadow-2xl hover:shadow-blue-500/25 hover:scale-105 transition-all duration-300 group/btn relative overflow-hidden">
                    <span className="relative z-10 flex items-center">
                      <span className="mr-2">🚀</span>
                      Start Building Today
                    </span>
                    <div className="absolute inset-0 bg-gradient-to-r from-white/20 to-transparent opacity-0 group-hover/btn:opacity-100 transition-opacity duration-300"></div>
                  </Button>
                </Link>
                <a href="https://github.com/connix-labs/api" target="_blank" rel="noopener noreferrer">
                  <Button variant="outline" className="border-slate-600 text-slate-300 hover:bg-slate-800 hover:border-slate-500 hover:text-white text-lg px-8 py-4 rounded-2xl hover:scale-105 transition-all duration-300 group/btn">
                    <span className="mr-2 group-hover/btn:scale-110 transition-transform duration-300">⭐</span>
                    Explore on GitHub
                  </Button>
                </a>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Enhanced Footer */}
      <footer className="bg-gradient-to-b from-slate-900 to-black text-white py-16 px-6 relative overflow-hidden">
        {/* Footer background effects */}
        <div className="absolute inset-0 opacity-5">
          <div className="absolute top-0 left-1/4 w-64 h-64 bg-blue-500 rounded-full blur-3xl"></div>
          <div className="absolute bottom-0 right-1/4 w-48 h-48 bg-purple-500 rounded-full blur-3xl"></div>
        </div>
        
        <div className="max-w-7xl mx-auto relative z-10">
          <div className="grid md:grid-cols-4 gap-8 mb-12">
            <div className="md:col-span-2">
              <div className="flex items-center mb-6 group">
                <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl flex items-center justify-center mr-3 group-hover:scale-110 group-hover:rotate-12 transition-all duration-300">
                  <span className="text-white font-bold">C</span>
                </div>
                <span className="text-2xl font-bold group-hover:text-blue-400 transition-colors duration-300">Connix</span>
              </div>
              <p className="text-slate-400 mb-6 max-w-md leading-relaxed hover:text-slate-300 transition-colors duration-300">
                Building the future of agent orchestration with open source tools, 
                powered by Nix for declarative and reproducible environments.
              </p>
              <div className="flex space-x-4">
                <a href="https://github.com/connix-labs/api" target="_blank" rel="noopener noreferrer" 
                   className="w-10 h-10 bg-slate-800 hover:bg-slate-700 hover:scale-110 rounded-lg flex items-center justify-center transition-all duration-300 group">
                  <svg className="w-5 h-5 group-hover:text-blue-400 transition-colors duration-300" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                  </svg>
                </a>
              </div>
            </div>
            
            <div>
              <h3 className="font-semibold mb-4 text-slate-200 hover:text-white transition-colors duration-300">Resources</h3>
              <ul className="space-y-3">
                <li><a href="#" className="text-slate-400 hover:text-white hover:translate-x-1 transition-all duration-300 inline-block">Documentation</a></li>
                <li><a href="#" className="text-slate-400 hover:text-white hover:translate-x-1 transition-all duration-300 inline-block">API Reference</a></li>
                <li><a href="#" className="text-slate-400 hover:text-white hover:translate-x-1 transition-all duration-300 inline-block">Examples</a></li>
                <li><a href="#" className="text-slate-400 hover:text-white hover:translate-x-1 transition-all duration-300 inline-block">Community</a></li>
              </ul>
            </div>
            
            <div>
              <h3 className="font-semibold mb-4 text-slate-200 hover:text-white transition-colors duration-300">Company</h3>
              <ul className="space-y-3">
                <li><a href="#" className="text-slate-400 hover:text-white hover:translate-x-1 transition-all duration-300 inline-block">About</a></li>
                <li><a href="#" className="text-slate-400 hover:text-white hover:translate-x-1 transition-all duration-300 inline-block">Blog</a></li>
                <li><a href="#" className="text-slate-400 hover:text-white hover:translate-x-1 transition-all duration-300 inline-block">Careers</a></li>
                <li><a href="#" className="text-slate-400 hover:text-white hover:translate-x-1 transition-all duration-300 inline-block">Contact</a></li>
              </ul>
            </div>
          </div>
          
          <div className="border-t border-slate-800 pt-8 flex flex-col md:flex-row justify-between items-center">
            <p className="text-slate-400 mb-4 md:mb-0 hover:text-slate-300 transition-colors duration-300">
              © 2024 Connix Labs. All rights reserved.
            </p>
            <div className="flex space-x-6">
              <a href="#" className="text-slate-400 hover:text-white transition-colors duration-300 text-sm hover:scale-105 inline-block">Privacy</a>
              <a href="#" className="text-slate-400 hover:text-white transition-colors duration-300 text-sm hover:scale-105 inline-block">Terms</a>
              <a href="#" className="text-slate-400 hover:text-white transition-colors duration-300 text-sm hover:scale-105 inline-block">Cookies</a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}

function AuthenticatedDashboard() {
  return (
    <div className="flex flex-col h-full">
      <div className="flex-1 p-8">
        <div className="max-w-7xl mx-auto">
          <div className="mb-8">
            <h1 className="text-3xl font-bold text-gray-900 mb-2">
              Welcome to Connix
            </h1>
            <p className="text-gray-600">
              You're successfully signed in! This is your dashboard.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div className="bg-white rounded-lg shadow-md p-6 border">
              <div className="flex items-center mb-4">
                <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                  <span className="text-blue-600 text-xl">📊</span>
                </div>
                <h3 className="ml-4 text-lg font-semibold text-gray-900">
                  Analytics
                </h3>
              </div>
              <p className="text-gray-600">View your data and insights</p>
            </div>

            <div className="bg-white rounded-lg shadow-md p-6 border">
              <div className="flex items-center mb-4">
                <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                  <span className="text-green-600 text-xl">⚙️</span>
                </div>
                <h3 className="ml-4 text-lg font-semibold text-gray-900">
                  Settings
                </h3>
              </div>
              <p className="text-gray-600">Manage your account preferences</p>
            </div>

            <div className="bg-white rounded-lg shadow-md p-6 border">
              <div className="flex items-center mb-4">
                <div className="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
                  <span className="text-purple-600 text-xl">🚀</span>
                </div>
                <h3 className="ml-4 text-lg font-semibold text-gray-900">
                  Projects
                </h3>
              </div>
              <p className="text-gray-600">Create and manage your projects</p>
            </div>
          </div>

          <div className="mt-8 bg-gradient-to-r from-blue-50 to-cyan-50 rounded-lg p-6 border">
            <h2 className="text-xl font-semibold text-gray-900 mb-2">
              Getting Started
            </h2>
            <p className="text-gray-600 mb-4">
              Welcome to Connix! Here are some quick actions to get you started:
            </p>
            <div className="flex flex-wrap gap-3">
              <Button className="bg-blue-600 hover:bg-blue-700">
                Create Project
              </Button>
              <Button variant="outline">View Documentation</Button>
              <Link to="/settings">
                <Button variant="outline">Account Settings</Button>
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}