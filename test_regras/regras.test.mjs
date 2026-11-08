// Testes das regras de segurança do PetCadê (firestore.rules).
// Rodar: cd test_regras && npm install && npm test
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, writeBatch, increment,
  arrayUnion, arrayRemove, collection, query, where, getDocs, addDoc,
} from 'firebase/firestore';

const env = await initializeTestEnvironment({
  projectId: 'demo-petcade',
  firestore: {
    rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    host: '127.0.0.1',
    port: 8085,
  },
});

// Pessoas: dono (Pedro), outra pessoa confirmada (Ana), sem e-mail confirmado (Zé)
const dono = env.authenticatedContext('pedro', { email_verified: true }).firestore();
const ana = env.authenticatedContext('ana', { email_verified: true }).firestore();
const ze = env.authenticatedContext('ze', { email_verified: false }).firestore();
const anonimo = env.unauthenticatedContext().firestore();

let ok = 0, falhas = 0;
async function caso(nome, fn) {
  try { await fn(); ok++; console.log('  ✓', nome); }
  catch (e) { falhas++; console.log('  ✗', nome, '\n     ', e.message); }
}

const petNovo = (donoId) => ({
  nome: 'Nina', especie: 'Gato', donoId, denuncias: 0, seguidores: [],
  status: 'perdido', criadoEm: new Date(),
});

async function preparar() {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (c) => {
    const db = c.firestore();
    await setDoc(doc(db, 'pets_perdidos/nina'), petNovo('pedro'));
    await setDoc(doc(db, 'pets_perdidos/antigo'), { nome: 'Rex', especie: 'Cachorro' });
    await setDoc(doc(db, 'usuarios/pedro'), { nome: 'Pedro', email: 'p@x.com', telefone: '11999', favoritos: [] });
    await setDoc(doc(db, 'usuarios/ana'), { nome: 'Ana', email: 'a@x.com', favoritos: [] });
  });
}

console.log('\nAnúncios');
await preparar();
await caso('quem não está logado não lê anúncios', () => assertFails(getDoc(doc(anonimo, 'pets_perdidos/nina'))));
await caso('logado lê anúncios', () => assertSucceeds(getDoc(doc(ze, 'pets_perdidos/nina'))));
await caso('e-mail confirmado publica anúncio', () => assertSucceeds(setDoc(doc(ana, 'pets_perdidos/p1'), petNovo('ana'))));
await caso('e-mail NÃO confirmado não publica', () => assertFails(setDoc(doc(ze, 'pets_perdidos/p2'), petNovo('ze'))));
await caso('não publica em nome de outra pessoa', () => assertFails(setDoc(doc(ana, 'pets_perdidos/p3'), petNovo('pedro'))));
await caso('não publica já com denúncias forjadas', () => assertFails(setDoc(doc(ana, 'pets_perdidos/p4'), { ...petNovo('ana'), denuncias: -5 })));
await caso('dono altera a localização', () => assertSucceeds(updateDoc(doc(dono, 'pets_perdidos/nina'), { localizacao: 'Vila Sônia' })));
await env.withSecurityRulesDisabled((c) => updateDoc(doc(c.firestore(), 'pets_perdidos/nina'), { denuncias: 2 }));
await caso('dono NÃO zera as denúncias', () => assertFails(updateDoc(doc(dono, 'pets_perdidos/nina'), { denuncias: 0, localizacao: 'x' })));
await caso('outra pessoa não edita o anúncio', () => assertFails(updateDoc(doc(ana, 'pets_perdidos/nina'), { nome: 'Hackeado' })));
await caso('outra pessoa não exclui o anúncio', () => assertFails(deleteDoc(doc(ana, 'pets_perdidos/nina'))));

console.log('\nSalvar anúncio (seguidores)');
await caso('Ana salva o anúncio (entra na lista)', () => assertSucceeds(updateDoc(doc(ana, 'pets_perdidos/nina'), { seguidores: arrayUnion('ana') })));
await caso('Ana não coloca outra pessoa na lista', () => assertFails(updateDoc(doc(ana, 'pets_perdidos/nina'), { seguidores: arrayUnion('ze') })));
await caso('Ana tira dos salvos', () => assertSucceeds(updateDoc(doc(ana, 'pets_perdidos/nina'), { seguidores: arrayRemove('ana') })));
await caso('salvar anúncio antigo (sem dono) funciona', () => assertSucceeds(updateDoc(doc(ana, 'pets_perdidos/antigo'), { seguidores: arrayUnion('ana') })));

console.log('\nDenúncias');
await preparar();
const denunciar = (db, uid, petId = 'nina') => {
  const b = writeBatch(db);
  b.set(doc(db, `denuncias/${petId}_${uid}`), { petId, autorId: uid, motivo: 'Golpe', detalhes: '', criadoEm: new Date() });
  b.update(doc(db, `pets_perdidos/${petId}`), { denuncias: increment(1) });
  return b.commit();
};
await caso('Ana denuncia (registro + contador juntos)', () => assertSucceeds(denunciar(ana, 'ana')));
await caso('Ana não denuncia duas vezes', () => assertFails(denunciar(ana, 'ana')));
await caso('Ana vê a própria denúncia', () => assertSucceeds(getDoc(doc(ana, 'denuncias/nina_ana'))));
await caso('dono NÃO vê quem denunciou', () => assertFails(getDoc(doc(dono, 'denuncias/nina_ana'))));
await caso('e-mail não confirmado não denuncia', () => assertFails(denunciar(ze, 'ze')));
await caso('dono não denuncia o próprio anúncio', () => assertFails(denunciar(dono, 'pedro')));
await caso('não dá para só aumentar o contador sem registrar', () => assertFails(updateDoc(doc(ana, 'pets_perdidos/nina'), { denuncias: increment(1) })));
await caso('não dá para pular o contador (+5)', async () => {
  // uma pessoa confirmada nova
  const bia = env.authenticatedContext('bia', { email_verified: true }).firestore();
  const b2 = writeBatch(bia);
  b2.set(doc(bia, 'denuncias/nina_bia'), { petId: 'nina', autorId: 'bia', motivo: 'Golpe', criadoEm: new Date() });
  b2.update(doc(bia, 'pets_perdidos/nina'), { denuncias: increment(5) });
  await assertFails(b2.commit());
});

console.log('\nPerfis (dados privados)');
await caso('cada um lê o próprio perfil', () => assertSucceeds(getDoc(doc(ana, 'usuarios/ana'))));
await caso('Ana NÃO lê e-mail/telefone do Pedro', () => assertFails(getDoc(doc(ana, 'usuarios/pedro'))));
await caso('Ana NÃO busca perfis de outros', () => assertFails(getDocs(query(collection(ana, 'usuarios'), where('favoritos', 'array-contains', 'nina')))));
await caso('Ana não altera o perfil do Pedro', () => assertFails(updateDoc(doc(ana, 'usuarios/pedro'), { nome: 'X' })));

console.log('\nNotificações');
await preparar();
const aviso = (autorId, paraId, tipo = 'avistamento', petId = 'nina') => ({
  paraId, autorId, tipo, titulo: 'Novo avistamento', mensagem: 'Vi na praça', petId, lida: false, criadoEm: new Date(),
});
await caso('Ana avisa o dono que viu o pet', () => assertSucceeds(addDoc(collection(ana, 'notificacoes'), aviso('ana', 'pedro'))));
await caso('não manda "avistamento" para quem não é o dono', () => assertFails(addDoc(collection(ana, 'notificacoes'), aviso('ana', 'ze'))));
await caso('não se passa por outra pessoa', () => assertFails(addDoc(collection(ana, 'notificacoes'), aviso('pedro', 'pedro'))));
await caso('e-mail não confirmado não manda avistamento', () => assertFails(addDoc(collection(ze, 'notificacoes'), aviso('ze', 'pedro'))));
await env.withSecurityRulesDisabled((c) => updateDoc(doc(c.firestore(), 'pets_perdidos/nina'), { seguidores: ['ana'] }));
await caso('dono avisa seguidores que o pet foi encontrado', () => assertSucceeds(addDoc(collection(dono, 'notificacoes'), aviso('pedro', 'ana', 'encontrado'))));
await caso('dono não manda "encontrado" para quem não segue', () => assertFails(addDoc(collection(dono, 'notificacoes'), aviso('pedro', 'ze', 'encontrado'))));
await caso('outra pessoa não manda "encontrado"', () => assertFails(addDoc(collection(ana, 'notificacoes'), aviso('ana', 'ana', 'encontrado'))));
const n = await env.withSecurityRulesDisabled(async (c) => { await setDoc(doc(c.firestore(), 'notificacoes/n1'), aviso('ana', 'pedro')); });
await caso('dono lê a própria notificação', () => assertSucceeds(getDoc(doc(dono, 'notificacoes/n1'))));
await caso('Ana não lê notificação do Pedro', () => assertFails(getDoc(doc(ana, 'notificacoes/n1'))));
await caso('dono marca como lida', () => assertSucceeds(updateDoc(doc(dono, 'notificacoes/n1'), { lida: true })));
await caso('dono não altera o texto da notificação', () => assertFails(updateDoc(doc(dono, 'notificacoes/n1'), { mensagem: 'x' })));
await caso('dono lista as próprias notificações', () => assertSucceeds(getDocs(query(collection(dono, 'notificacoes'), where('paraId', '==', 'pedro')))));
await caso('dono lista os próprios anúncios', () => assertSucceeds(getDocs(query(collection(dono, 'pets_perdidos'), where('donoId', '==', 'pedro')))));

await env.cleanup();
console.log(`\n${ok} passaram, ${falhas} falharam`);
process.exit(falhas ? 1 : 0);
