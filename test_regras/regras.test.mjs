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

console.log('\nPerfis públicos');
await preparar();
const perfil = { nome: 'Ana S.', foto: '', fotoUrl: '' };
await caso('cada um publica o próprio perfil público', () => assertSucceeds(setDoc(doc(ana, 'perfis/ana'), perfil)));
await caso('logado lê perfil público de outra pessoa', () => assertSucceeds(getDoc(doc(dono, 'perfis/ana'))));
await caso('não publica perfil em nome de outra pessoa', () => assertFails(setDoc(doc(ana, 'perfis/pedro'), perfil)));
await caso('perfil público não aceita e-mail/telefone', () => assertFails(setDoc(doc(ana, 'perfis/ana'), { ...perfil, email: 'a@x.com' })));

console.log('\nPrestígio');
await preparar();
const interesse = (uid, petId = 'nina', donoId = 'pedro') => ({ petId, uid, donoId, criadoEm: new Date() });
const ajuda = (ajudanteId, petId = 'nina') => ({ petId, petNome: 'Nina', ajudanteId, donoId: 'pedro', criadoEm: new Date() });
await caso('Ana vira interessada no anúncio do Pedro', () => assertSucceeds(setDoc(doc(ana, 'interessados/nina_ana'), interesse('ana'))));
await caso('não registra interesse em nome de outra pessoa', () => assertFails(setDoc(doc(ana, 'interessados/nina_ze'), interesse('ze'))));
await caso('dono não vira interessado no próprio anúncio', () => assertFails(setDoc(doc(dono, 'interessados/nina_pedro'), interesse('pedro'))));
await caso('não mente quem é o dono', () => assertFails(setDoc(doc(ze, 'interessados/nina_ze'), interesse('ze', 'nina', 'ana'))));
await caso('dono lista os interessados do anúncio', () => assertSucceeds(getDocs(query(collection(dono, 'interessados'), where('donoId', '==', 'pedro'), where('petId', '==', 'nina')))));
await caso('outra pessoa não lista interessados do Pedro', () => assertFails(getDocs(query(collection(ze, 'interessados'), where('donoId', '==', 'pedro')))));
await caso('dono NÃO credita quem não avisou/conversou', () => assertFails(setDoc(doc(dono, 'ajudas/nina'), ajuda('ze'))));
await caso('Ana NÃO credita a si mesma', () => assertFails(setDoc(doc(ana, 'ajudas/nina'), { ...ajuda('ana'), donoId: 'ana' })));
const creditar = (db) => {
  const b = writeBatch(db);
  b.set(doc(db, 'ajudas/nina'), ajuda('ana'));
  b.set(doc(collection(db, 'notificacoes')), { paraId: 'ana', autorId: 'pedro', tipo: 'ajuda', titulo: 'x', mensagem: 'Obrigado', petId: 'nina', lida: false, criadoEm: new Date() });
  return b.commit();
};
await caso('dono credita a Ana (ajuda + notificação)', () => assertSucceeds(creditar(dono)));
await caso('não dá para creditar duas vezes o mesmo pet', () => assertFails(creditar(dono)));
await caso('qualquer logado vê o prestígio (contagem de ajudas)', () => assertSucceeds(getDocs(query(collection(ze, 'ajudas'), where('ajudanteId', '==', 'ana')))));
await caso('notificação "ajuda" falsa é bloqueada', () => assertFails(addDoc(collection(ze, 'notificacoes'), { paraId: 'ze', autorId: 'ze', tipo: 'ajuda', mensagem: 'x', petId: 'nina' })));

console.log('\nBate-papo');
await preparar();
const conversa = { participantes: ['ana', 'pedro'], ultimaMensagem: '', ultimoAutor: '', lidaPor: {}, petNome: 'Nina', criadoEm: new Date() };
await caso('Ana abre conversa com o Pedro', () => assertSucceeds(setDoc(doc(ana, 'conversas/ana_pedro'), conversa)));
await caso('não cria conversa entre outras duas pessoas', () => assertFails(setDoc(doc(ze, 'conversas/ana_pedro2'), { ...conversa, participantes: ['ana', 'pedro2'] })));
await caso('id da conversa precisa bater com os participantes', () => assertFails(setDoc(doc(ze, 'conversas/x_ze'), { ...conversa, participantes: ['ana', 'ze'] })));
await caso('Pedro lê a conversa', () => assertSucceeds(getDoc(doc(dono, 'conversas/ana_pedro'))));
await caso('Zé NÃO lê a conversa dos dois', () => assertFails(getDoc(doc(ze, 'conversas/ana_pedro'))));
await caso('cada um lista só as próprias conversas', () => assertSucceeds(getDocs(query(collection(ana, 'conversas'), where('participantes', 'array-contains', 'ana')))));
await caso('Zé NÃO lista conversas da Ana', () => assertFails(getDocs(query(collection(ze, 'conversas'), where('participantes', 'array-contains', 'ana')))));
const enviar = (db, autorId, extra = {}) => {
  const b = writeBatch(db);
  b.set(doc(collection(db, 'conversas/ana_pedro/mensagens')), { autorId, tipo: 'texto', texto: 'Oi! Vi sua gata', criadoEm: new Date(), ...extra });
  b.update(doc(db, 'conversas/ana_pedro'), { ultimaMensagem: 'Oi! Vi sua gata', ultimoAutor: autorId, ultimoEnvio: new Date() });
  return b.commit();
};
await caso('Ana manda mensagem', () => assertSucceeds(enviar(ana, 'ana')));
await caso('Pedro responde', () => assertSucceeds(enviar(dono, 'pedro')));
await caso('Ana NÃO manda mensagem como se fosse o Pedro', () => assertFails(enviar(ana, 'pedro')));
await caso('Zé NÃO manda mensagem na conversa dos dois', () => assertFails(addDoc(collection(ze, 'conversas/ana_pedro/mensagens'), { autorId: 'ze', tipo: 'texto', texto: 'oi' })));
await caso('Zé NÃO lê as mensagens dos dois', () => assertFails(getDocs(collection(ze, 'conversas/ana_pedro/mensagens'))));
await caso('Pedro lê as mensagens', () => assertSucceeds(getDocs(collection(dono, 'conversas/ana_pedro/mensagens'))));
await caso('Pedro marca como lida', () => assertSucceeds(updateDoc(doc(dono, 'conversas/ana_pedro'), { 'lidaPor.pedro': new Date() })));
await caso('não troca os participantes da conversa', () => assertFails(updateDoc(doc(ana, 'conversas/ana_pedro'), { participantes: ['ana', 'ze'] })));
await caso('áudio/foto acima do limite é bloqueado', () => assertFails(enviar(ana, 'ana', { tipo: 'imagem', texto: '', dados: 'x'.repeat(600001) })));

await env.cleanup();
console.log(`\n${ok} passaram, ${falhas} falharam`);
process.exit(falhas ? 1 : 0);
