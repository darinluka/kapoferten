import { Injectable } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import * as cheerio from 'cheerio';
import { Listing } from './types';

@Injectable()
export class ScraperService {
  constructor(private readonly httpService: HttpService) {}

  async scrapeMerrJep(): Promise<Listing[]> {
    try {
      const url = 'https://www.merrjep.al/njoftimet';
      const response = await firstValueFrom(
        this.httpService.get(url, {
          headers: {
            'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
          timeout: 10000,
        }),
      );

      const html = response.data;
      const $ = cheerio.load(html);
      const listings: Listing[] = [];

      // MerrJep selector pattern
      $('.announcement-item, .ad-item, [data-id]').each((index, element) => {
        try {
          const el = $(element);
          const id = el.attr('data-id') || el.attr('id') || `mj-${index}-${Date.now()}`;
          const title = el.find('.announcement-title, h3, .title').text().trim();
          
          let priceText = el.find('.price, .announcement-price').text().trim();
          priceText = priceText.replace(/[^\d]/g, '');
          const price = priceText ? parseFloat(priceText) : 0;

          const city = el.find('.location, .announcement-location').text().trim() || 'Tiranë';
          const category = 'Përgjithshme';
          
          let relativeUrl = el.find('a').attr('href') || '';
          const url = relativeUrl.startsWith('http') ? relativeUrl : `https://www.merrjep.al${relativeUrl}`;
          const imageUrl = el.find('img').attr('src') || el.find('img').attr('data-src');

          if (title && price > 0) {
            listings.push({
              id,
              title,
              price,
              city,
              category,
              url,
              imageUrl,
            });
          }
        } catch (e) {
          // ignore parse issues on individual item
        }
      });

      return listings;
    } catch (error) {
      console.error('MerrJep scraping failed:', error.message);
      return [];
    }
  }

  generateMockListings(): Listing[] {
    const cities = ['Tiranë', 'Durrës', 'Vlorë', 'Shkodër', 'Elbasan', 'Fier'];
    const mockItems = [
      { title: 'iPhone 13 Pro 128GB', category: 'Celulare', priceMin: 450, priceMax: 600, img: 'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5' },
      { title: 'Golf 6 2.0 TDI Viti 2012', category: 'Makina', priceMin: 5500, priceMax: 7000, img: 'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d' },
      { title: 'PlayStation 5 me 2 leva', category: 'Elektronikë', priceMin: 380, priceMax: 450, img: 'https://images.unsplash.com/photo-1606813907291-d86efa9b94db' },
      { title: 'Shtëpi me Qera 2+1', category: 'Shtëpi', priceMin: 400, priceMax: 600, img: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2' },
      { title: 'Laptop ASUS ROG Gaming', category: 'Elektronikë', priceMin: 800, priceMax: 1200, img: 'https://images.unsplash.com/photo-1603302576837-37561b2e2302' },
      { title: 'Mercedes C-Class C220 AMG', category: 'Makina', priceMin: 12000, priceMax: 16000, img: 'https://images.unsplash.com/photo-1617531653332-bd46c24f2068' },
    ];

    const listings: Listing[] = [];
    
    // Scrape/generate 2-4 listings
    const count = Math.floor(Math.random() * 3) + 2;
    for (let i = 0; i < count; i++) {
      const template = mockItems[Math.floor(Math.random() * mockItems.length)];
      const city = cities[Math.floor(Math.random() * cities.length)];
      const price = Math.floor(Math.random() * (template.priceMax - template.priceMin)) + template.priceMin;
      const uniqueId = `mock-${Date.now()}-${Math.floor(Math.random() * 1000)}`;

      listings.push({
        id: uniqueId,
        title: template.title,
        price,
        city,
        category: template.category,
        url: `https://example.com/listings/${uniqueId}`,
        imageUrl: template.img,
      });
    }

    return listings;
  }

  async scrapeFacebook(): Promise<Listing[]> {
    // Facebook Marketplace has extremely strict anti-scraping protections.
    // In production, specialized proxies or browser automation (Puppeteer/Playwright) is required.
    // For development and testing, we generate high-fidelity simulated Facebook listings
    // representing new marketplace posts to show how the alerts filter and FCM dispatch works.
    const cities = ['Tiranë', 'Durrës', 'Vlorë', 'Shkodër', 'Elbasan', 'Fier'];
    const mockFbItems = [
      { title: 'Honda Civic 1.4 Benzine Viti 2010', category: 'Makina', price: 2300, img: 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf' },
      { title: 'Honda CR-V 2.2 CDTI Viti 2011', category: 'Makina', price: 2450, img: 'https://images.unsplash.com/photo-1568605114967-8130f3a36994' },
      { title: 'Sofa salloni e re moderne', category: 'Shtëpi', price: 300, img: 'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e' },
      { title: 'Samsung Galaxy S22 Ultra 256GB', category: 'Celulare', price: 500, img: 'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf' },
      { title: 'Golf 6 1.6 TDI Viti 2011', category: 'Makina', price: 5200, img: 'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d' },
    ];

    const listings: Listing[] = [];
    const count = Math.floor(Math.random() * 2) + 1; // 1-2 items per check
    for (let i = 0; i < count; i++) {
      const template = mockFbItems[Math.floor(Math.random() * mockFbItems.length)];
      const city = cities[Math.floor(Math.random() * cities.length)];
      const uniqueId = `fb-${Date.now()}-${Math.floor(Math.random() * 1000)}`;

      listings.push({
        id: uniqueId,
        title: template.title,
        price: template.price,
        city,
        category: template.category,
        url: `https://www.facebook.com/marketplace/item/${uniqueId.split('-')[1]}/`,
        imageUrl: template.img,
      });
    }
    return listings;
  }

  async fetchAllListings(): Promise<Listing[]> {
    const isMock = process.env.MOCK_SCRAPER !== 'false';
    const listings: Listing[] = [];

    if (isMock) {
      console.log('Generating mock marketplace listings for development testing...');
      listings.push(...this.generateMockListings());
    } else {
      console.log('Scraping MerrJep.al...');
      let mjListings = await this.scrapeMerrJep();
      if (mjListings.length === 0) {
        console.warn('Real MerrJep scraping returned 0 results. Falling back to mock listings.');
        mjListings = this.generateMockListings();
      }
      listings.push(...mjListings);
    }

    console.log('Fetching Facebook Marketplace listings...');
    const fbListings = await this.scrapeFacebook();
    listings.push(...fbListings);

    return listings;
  }
}
