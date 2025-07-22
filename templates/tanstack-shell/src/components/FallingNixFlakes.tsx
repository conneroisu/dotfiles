import { useCallback, useEffect, useRef, useState } from "react";

interface NixFlake {
  id: number;
  x: number;
  y: number;
  size: number;
  speed: number;
  opacity: number;
  drift: number;
  rotation: number;
  rotationSpeed: number;
}

interface FallingNixFlakesProps {
  count?: number;
  className?: string;
  /** Whether to reduce motion for accessibility */
  reduceMotion?: boolean;
}

export function FallingNixFlakes({
  count = 15,
  className = "",
  reduceMotion = false,
}: FallingNixFlakesProps) {
  const [flakes, setFlakes] = useState<Array<NixFlake>>([]);
  const [isClient, setIsClient] = useState(false);
  const animationFrameRef = useRef<number>();
  const lastTimeRef = useRef<number>(0);

  // Ensure we're on the client side
  useEffect(() => {
    setIsClient(true);
  }, []);

  // Initialize flakes - only on client side
  useEffect(() => {
    if (!isClient || typeof window === 'undefined') {
      return;
    }

    const initialFlakes: Array<NixFlake> = Array.from(
      { length: count },
      (_, i) => ({
        id: i,
        x: Math.random() * 100,
        y: Math.random() * -100 - 20, // Start higher off screen
        size: Math.random() * 0.6 + 0.4, // Smaller range for subtlety
        speed: Math.random() * 1.5 + 0.5, // Slower, more gentle
        opacity: Math.random() * 0.4 + 0.15, // More subtle opacity
        drift: (Math.random() - 0.5) * 1.5, // More balanced drift
        rotation: Math.random() * 360,
        rotationSpeed: (Math.random() - 0.5) * 2,
      }),
    );

    setFlakes(initialFlakes);
  }, [count, isClient]);

  // Animation loop with requestAnimationFrame - client-side only
  const animateFlakes = useCallback(
    (currentTime: number) => {
      if (reduceMotion || !isClient || typeof window === 'undefined' || typeof requestAnimationFrame === 'undefined') {
        return;
      }

      const deltaTime = currentTime - lastTimeRef.current;

      // Throttle to ~60fps
      if (deltaTime >= 16) {
        setFlakes((prevFlakes) =>
          prevFlakes.map((flake) => {
            const speedMultiplier = deltaTime / 16;
            let newY = flake.y + flake.speed * speedMultiplier;
            let newX = flake.x + flake.drift * 0.05 * speedMultiplier;
            let newRotation =
              flake.rotation + flake.rotationSpeed * speedMultiplier;

            // Reset flake when it goes off screen
            if (newY > 110) {
              newY = -20;
              newX = Math.random() * 100;
              newRotation = Math.random() * 360;
            }

            // Wrap horizontal movement
            if (newX > 100) {
              newX = -5;
            }
            if (newX < -5) {
              newX = 100;
            }

            // Keep rotation in bounds
            if (newRotation > 360) {
              newRotation -= 360;
            }
            if (newRotation < 0) {
              newRotation += 360;
            }

            return {
              ...flake,
              x: newX,
              y: newY,
              rotation: newRotation,
            };
          }),
        );

        lastTimeRef.current = currentTime;
      }

      if (typeof requestAnimationFrame !== 'undefined') {
        animationFrameRef.current = requestAnimationFrame(animateFlakes);
      }
    },
    [reduceMotion, isClient],
  );

  useEffect(() => {
    if (!reduceMotion && isClient && typeof window !== 'undefined' && typeof requestAnimationFrame !== 'undefined') {
      animationFrameRef.current = requestAnimationFrame(animateFlakes);
    }

    return () => {
      if (animationFrameRef.current && typeof cancelAnimationFrame !== 'undefined') {
        cancelAnimationFrame(animationFrameRef.current);
      }
    };
  }, [animateFlakes, reduceMotion, isClient]);

  // Accurate Nix logo based on official NixOS artwork
  const NixFlakeIcon = ({
    size,
    opacity,
    rotation,
    id,
  }: {
    size: number;
    opacity: number;
    rotation: number;
    id: number;
  }) => {
    // Generate unique gradient IDs for each flake instance to avoid DOM conflicts
    const gradientId = `nixGradient-${id}`;
    const innerGradientId = `nixInnerGradient-${id}`;

    return (
      <svg
        width={size * 20}
        height={size * 20}
        viewBox="0 0 100 100"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        style={{
          opacity,
          transform: `rotate(${rotation}deg)`,
          filter: "drop-shadow(0 0 4px rgba(147, 51, 234, 0.3))",
        }}
        className="will-change-transform"
      >
        {/* Six triangular segments forming the Nix hexagonal snowflake */}
        {Array.from({ length: 6 }, (_, i) => {
          const angle = i * 60;
          return (
            <g
              key={i}
              transform={`rotate(${angle} 50 50)`}
            >
              <path
                d="M50 20 L65 45 L50 50 L35 45 Z"
                fill={`url(#${gradientId})`}
                className="opacity-80"
              />
              <path
                d="M50 30 L60 42 L50 45 L40 42 Z"
                fill={`url(#${innerGradientId})`}
                className="opacity-90"
              />
            </g>
          );
        })}

        {/* Gradient definitions with unique IDs */}
        <defs>
          <linearGradient
            id={gradientId}
            x1="0%"
            y1="0%"
            x2="100%"
            y2="100%"
          >
            <stop
              offset="0%"
              stopColor="#ffffff"
              stopOpacity="0.6"
            />
            <stop
              offset="50%"
              stopColor="#a855f7"
              stopOpacity="0.8"
            />
            <stop
              offset="100%"
              stopColor="#7c3aed"
              stopOpacity="0.4"
            />
          </linearGradient>
          <linearGradient
            id={innerGradientId}
            x1="0%"
            y1="0%"
            x2="100%"
            y2="100%"
          >
            <stop
              offset="0%"
              stopColor="#e879f9"
              stopOpacity="0.7"
            />
            <stop
              offset="100%"
              stopColor="#c084fc"
              stopOpacity="0.5"
            />
          </linearGradient>
        </defs>
      </svg>
    );
  };

  // Don't render if motion is reduced or not on client side
  if (reduceMotion || !isClient) {
    return null;
  }

  return (
    <div
      className={`fixed inset-0 pointer-events-none overflow-hidden z-0 ${className}`}
      role="presentation"
      aria-hidden="true"
    >
      {flakes.map((flake) => (
        <div
          key={flake.id}
          className="absolute will-change-transform"
          style={{
            left: `${flake.x}%`,
            top: `${flake.y}%`,
            transform: `translate(-50%, -50%)`,
          }}
        >
          <NixFlakeIcon
            size={flake.size}
            opacity={flake.opacity}
            rotation={flake.rotation}
            id={flake.id}
          />
        </div>
      ))}
    </div>
  );
}
