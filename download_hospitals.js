const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

const hospitals = [
    { name: 'montreal_general', url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Montreal_General_Hospital.jpg/800px-Montreal_General_Hospital.jpg' },
    { name: 'chum', url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/98/CHUM_Phase_2.jpg/800px-CHUM_Phase_2.jpg' },
    { name: 'sainte_justine', url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/H%C3%B4pital_Sainte-Justine_2017.jpg/800px-H%C3%B4pital_Sainte-Justine_2017.jpg' },
    { name: 'maisonneuve_rosemont', url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/H%C3%B4pital_Maisonneuve-Rosemont_-_Pavillon_Maisonneuve_01.jpg/800px-H%C3%B4pital_Maisonneuve-Rosemont_-_Pavillon_Maisonneuve_01.jpg' },
    { name: 'sacre_coeur', url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/52/H%C3%B4pital_du_Sacr%C3%A9-C%C5%93ur_de_Montr%C3%A9al_04.jpg/800px-H%C3%B4pital_du_Sacr%C3%A9-C%C5%93ur_de_Montr%C3%A9al_04.jpg' },
    { name: 'jewish_general', url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f3/Jewish_General_Hospital_Pavilion_K_2016.jpg/800px-Jewish_General_Hospital_Pavilion_K_2016.jpg' },
    { name: 'cusm_glen', url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/CUSM_Site_Glen_05.jpg/800px-CUSM_Site_Glen_05.jpg' },
    { name: 'verdun', url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1e/H%C3%B4pital_de_Verdun_03.jpg/800px-H%C3%B4pital_de_Verdun_03.jpg' },
    { name: 'santa_cabrini', url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/H%C3%B4pital_Santa_Cabrini_02.jpg/800px-H%C3%B4pital_Santa_Cabrini_02.jpg' },
    { name: 'jean_talon', url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/H%C3%B4pital_Jean-Talon_03.jpg/800px-H%C3%B4pital_Jean-Talon_03.jpg' },
    { name: 'charles_lemoyne', url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/H%C3%B4pital_Charles-Le_Moyne_%28vue_a%C3%A9rienne%29.jpg/800px-H%C3%B4pital_Charles-Le_Moyne_%28vue_a%C3%A9rienne%29.jpg' },
    { name: 'pierre_boucher', url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6c/H%C3%B4pital_Pierre-Boucher.jpg/800px-H%C3%B4pital_Pierre-Boucher.jpg' },
    { name: 'cite_sante', url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/29/H%C3%B4pital_Cit%C3%A9-de-la-Sant%C3%A9_Laval.jpg/800px-H%C3%B4pital_Cit%C3%A9-de-la-Sant%C3%A9_Laval.jpg' },
    { name: 'enfant_jesus', url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/H%C3%B4pital_de_l%27Enfant-J%C3%A9sus.jpg/800px-H%C3%B4pital_de_l%27Enfant-J%C3%A9sus.jpg' },
    { name: 'st_francois_assise', url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/75/H%C3%B4pital_Saint-Fran%C3%A7ois_d%27Assise_01.jpg/800px-H%C3%B4pital_Saint-Fran%C3%A7ois_d%27Assise_01.jpg' },
    { name: 'st_eustache', url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a8/H%C3%B4pital_de_Saint-Eustache.jpg/800px-H%C3%B4pital_de_Saint-Eustache.jpg' },
    { name: 'st_jerome', url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c7/H%C3%B4pital_r%C3%A9gional_de_Saint-J%C3%A9r%C3%B4me.jpg/800px-H%C3%B4pital_r%C3%A9gional_de_Saint-J%C3%A9r%C3%B4me.jpg' },
    { name: 'hull', url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/64/H%C3%B4pital_de_Hull.jpg/800px-H%C3%B4pital_de_Hull.jpg' },
    { name: 'trois_rivieres', url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Centre_hospitalier_r%C3%A9gional_de_Trois-Rivi%C3%A8res.jpg/800px-Centre_hospitalier_r%C3%A9gional_de_Trois-Rivi%C3%A8res.jpg' },
    { name: 'sherbrooke', url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/CHUS_-_H%C3%B4tel-Dieu.jpg/800px-CHUS_-_H%C3%B4tel-Dieu.jpg' }
];

const downloadImage = (url, filepath) => {
    return new Promise((resolve, reject) => {
        const client = url.startsWith('https') ? https : http;
        const options = {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Referer': 'https://en.wikipedia.org/',
                'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8'
            }
        };
        client.get(url, options, (res) => {
            if (res.statusCode === 200) {
                res.pipe(fs.createWriteStream(filepath))
                    .on('error', reject)
                    .once('close', () => resolve(filepath));
            } else if (res.statusCode === 301 || res.statusCode === 302) {
                // Handle redirects if necessary
                downloadImage(res.headers.location, filepath).then(resolve).catch(reject);
            } else {
                res.resume();
                reject(new Error(`Request Failed With a Status Code: ${res.statusCode}`));
            }
        }).on('error', reject);
    });
};

async function main() {
    const uploadDir = path.join(__dirname, 'server', 'uploads', 'hospitals');
    if (!fs.existsSync(uploadDir)) {
        fs.mkdirSync(uploadDir, { recursive: true });
    }

    for (const h of hospitals) {
        const ext = path.extname(h.url) || '.jpg';
        const filename = `${h.name}${ext}`;
        const filepath = path.join(uploadDir, filename);
        try {
            console.log(`Downloading ${h.name}...`);
            await downloadImage(h.url, filepath);
            console.log(`✅ Saved to ${filepath}`);
            // Wait 5 seconds to avoid 429
            await new Promise(resolve => setTimeout(resolve, 5000));
        } catch (e) {
            console.error(`❌ Failed to download ${h.name} from source: ${e.message}`);
            console.log(`⚠️ Attempting to download placeholder for ${h.name}...`);
            try {
                // Fallback to placehold.co which is reliable for this purpose
                const placeholderUrl = `https://placehold.co/800x600/e0f7fa/006064.png?text=${encodeURIComponent(h.name)}`;
                // Use .png for placeholder but save to original extension path to keep it simple or force png
                // Actually pg_init expects whatever we saved. Let's just overwrite the extension to .png if we use placeholder
                // But pg_init has hardcoded filenames.
                // Let's just save the placeholder content to the filepath (even if it says .jpg, it will be a png, which browsers handle fine usually, or we can be stricter)
                // For simplicity, we just write the bytes.
                await downloadImage(placeholderUrl, filepath);
                console.log(`✅ Saved PLACEHOLDER to ${filepath}`);
                await new Promise(resolve => setTimeout(resolve, 1000));
            } catch (ex) {
                console.error(`❌ Failed to download placeholder for ${h.name}: ${ex.message}`);
            }
        }
    }
}

main();
