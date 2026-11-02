// Small hand-written SVG charts. No chart library: this is an admin tool that
// holds production data, and every dependency here is one more thing to trust.
//
// Palette slots come from CSS custom properties so light and dark are one
// definition. Colours were validated for colour-blind separation and contrast
// before being written down; see the README.

const PAD = { top: 14, right: 16, bottom: 26, left: 44 };

const svgEl = (name, attrs = {}) => {
  const node = document.createElementNS('http://www.w3.org/2000/svg', name);
  for (const [k, v] of Object.entries(attrs)) node.setAttribute(k, v);
  return node;
};

const niceMax = (value) => {
  if (value <= 5) return 5;
  const magnitude = 10 ** Math.floor(Math.log10(value));
  return Math.ceil(value / magnitude) * magnitude;
};

const shortDay = (iso) => {
  const d = new Date(iso);
  return `${d.getDate()}/${d.getMonth() + 1}`;
};

/**
 * A multi-series daily line chart.
 * `series` is [{ key, label, colour }]; `rows` is the RPC's daily output.
 */
export function lineChart(container, rows, series, { height = 230 } = {}) {
  container.innerHTML = '';
  if (!rows.length) {
    container.innerHTML = '<p class="empty">Bu aralıkta veri yok.</p>';
    return;
  }

  const width = Math.max(container.clientWidth || 640, 320);
  const max = niceMax(
    Math.max(1, ...rows.flatMap((r) => series.map((s) => Number(r[s.key]) || 0)))
  );
  const plotW = width - PAD.left - PAD.right;
  const plotH = height - PAD.top - PAD.bottom;
  const x = (i) =>
    PAD.left + (rows.length === 1 ? plotW / 2 : (i / (rows.length - 1)) * plotW);
  const y = (v) => PAD.top + plotH - (v / max) * plotH;

  const svg = svgEl('svg', {
    viewBox: `0 0 ${width} ${height}`,
    width: '100%',
    height,
    role: 'img',
  });

  // Recessive gridlines and value axis.
  for (let i = 0; i <= 4; i++) {
    const value = (max / 4) * i;
    svg.append(
      svgEl('line', {
        x1: PAD.left,
        x2: width - PAD.right,
        y1: y(value),
        y2: y(value),
        class: 'grid',
      })
    );
    const label = svgEl('text', {
      x: PAD.left - 8,
      y: y(value) + 4,
      class: 'axis',
      'text-anchor': 'end',
    });
    label.textContent = String(Math.round(value));
    svg.append(label);
  }

  // Date ticks: first, middle and last only, so they never collide.
  for (const i of new Set([0, Math.floor((rows.length - 1) / 2), rows.length - 1])) {
    const tick = svgEl('text', {
      x: x(i),
      y: height - 8,
      class: 'axis',
      'text-anchor': i === 0 ? 'start' : i === rows.length - 1 ? 'end' : 'middle',
    });
    tick.textContent = shortDay(rows[i].day);
    svg.append(tick);
  }

  for (const s of series) {
    const points = rows
      .map((r, i) => `${x(i)},${y(Number(r[s.key]) || 0)}`)
      .join(' ');
    svg.append(
      svgEl('polyline', { points, fill: 'none', stroke: s.colour, 'stroke-width': 2,
        'stroke-linejoin': 'round', 'stroke-linecap': 'round' })
    );
    // A marker on the last point anchors the direct label.
    const last = rows.length - 1;
    svg.append(
      svgEl('circle', {
        cx: x(last),
        cy: y(Number(rows[last][s.key]) || 0),
        r: 4,
        fill: s.colour,
        stroke: 'var(--surface-1)',
        'stroke-width': 2,
      })
    );
  }

  container.append(svg);

  // Crosshair tooltip.
  const tip = document.createElement('div');
  tip.className = 'tooltip';
  tip.hidden = true;
  container.append(tip);
  const rule = svgEl('line', { class: 'crosshair', y1: PAD.top, y2: PAD.top + plotH });
  rule.setAttribute('visibility', 'hidden');
  svg.append(rule);

  svg.addEventListener('pointermove', (event) => {
    const box = svg.getBoundingClientRect();
    const px = ((event.clientX - box.left) / box.width) * width;
    const i = Math.max(
      0,
      Math.min(rows.length - 1, Math.round(((px - PAD.left) / plotW) * (rows.length - 1)))
    );
    rule.setAttribute('x1', x(i));
    rule.setAttribute('x2', x(i));
    rule.setAttribute('visibility', 'visible');
    tip.hidden = false;
    tip.innerHTML =
      `<strong>${shortDay(rows[i].day)}</strong>` +
      series
        .map(
          (s) =>
            `<span><i style="background:${s.colour}"></i>${s.label}: ${
              rows[i][s.key] ?? 0
            }</span>`
        )
        .join('');
    const left = Math.min(Math.max(8, (x(i) / width) * box.width - 60), box.width - 150);
    tip.style.left = `${left}px`;
  });
  svg.addEventListener('pointerleave', () => {
    rule.setAttribute('visibility', 'hidden');
    tip.hidden = true;
  });
}

/** Legend: identity is never colour alone, so every series is named. */
export function legend(container, series) {
  container.innerHTML = series
    .map((s) => `<span class="key"><i style="background:${s.colour}"></i>${s.label}</span>`)
    .join('');
}
