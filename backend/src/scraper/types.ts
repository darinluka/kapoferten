export interface Listing {
  id: string;       // Unique marketplace post ID
  title: string;    // Title of the post
  price: number;    // Numeric price
  city: string;     // City location
  category: string; // Category (e.g. Makina, Celulare, Shtëpi)
  url: string;      // Direct link to listing
  imageUrl?: string;// Preview image url
}
