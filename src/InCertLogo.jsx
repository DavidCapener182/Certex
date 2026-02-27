import React, { useState } from 'react';

export default function InCertLogo({ className = '', width = 240, height = 60 }) {
  const [isHovered, setIsHovered] = useState(false);

  return (
    <div
      className={className}
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'flex-start',
        width,
        height,
        transition: 'transform 180ms ease, filter 180ms ease',
        transform: isHovered ? 'translateY(-1px) scale(1.01)' : 'translateY(0) scale(1)',
        filter: isHovered ? 'drop-shadow(0 8px 14px rgba(15, 23, 42, 0.2))' : 'none',
      }}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      <img
        src="/icons/incert-logo.png"
        alt="InCert by InCommand"
        width={width}
        height={height}
        style={{
          display: 'block',
          objectFit: 'contain',
          objectPosition: 'left center',
          maxWidth: '100%',
          maxHeight: '100%',
        }}
      />
    </div>
  );
}
