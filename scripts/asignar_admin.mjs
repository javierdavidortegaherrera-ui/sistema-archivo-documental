import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

const uid = process.argv[2];
if (!uid || !process.env.GOOGLE_APPLICATION_CREDENTIALS || !process.env.GOOGLE_CLOUD_PROJECT) {
  console.error('Uso: configurar GOOGLE_APPLICATION_CREDENTIALS y GOOGLE_CLOUD_PROJECT; node scripts/asignar_admin.mjs <UID>');
  process.exit(1);
}

initializeApp({ credential: applicationDefault(), projectId: process.env.GOOGLE_CLOUD_PROJECT });
const usuario = await getAuth().getUser(uid);
if (!usuario.email) {
  throw new Error('El UID debe pertenecer a una cuenta con correo preautorizada.');
}
await getAuth().setCustomUserClaims(uid, { ...(usuario.customClaims ?? {}), admin: true });
console.log(`Privilegio administrativo asignado al UID ${uid}. Cierra e inicia sesión para renovar el token.`);
