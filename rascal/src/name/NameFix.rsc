module name::NameFix

import name::Gensym;
import name::HygienicCorrectness;
import name::Relation;
import name::Names;
import IO;
import Map;
import String;


&T rename(&T t, map[ID,str] subst) {
  return visit (t) {
    case str x => setID(subst[getID(x)], getID(x)) 
      when getID(x) in subst
  };
}


Edges badBindings(<Vs,Es,Ns>, <Vt,Et,Nt>) {
  notPreserveVar1 =    (u:Et[u] | u <- Vs & Vt, u in Et, u in Es, Es[u] != Et[u]);
  notPreserveVar2 =    (u:Et[u] | u <- Vs & Vt, u in Et, u notin Es, u != Et[u]);
  notPreserveDef  =    (u:Et[u] | u <- Vt, u in Et, u notin Vs, Et[u] in Vs);
  
  //println("not preserve source vars 1: <notPreserveVar1>");
  //println("not preserve source vars 2: <notPreserveVar2>");
  //println("not preserve source defs  : <notPreserveDef>");
  
  return notPreserveVar1 + notPreserveVar2 + notPreserveDef;
}

tuple[map[ID,str],map[ID,str]] compRenamings(<Vs,Es,Ns>, <Vt,Et,Nt>, t, badDefs) {
  EsClosure = (Es<0,1>)+;
  Nsrc = ();
  Nsyn = ();
  
  for (vd <- badDefs) {
    fresh = gensym(Nt[vd], Nt<1> + Nsrc<1> + Nsyn<1>);
    if (vd in Vs && vd notin Nsrc)
      Nsrc += (vd:fresh) + (v:fresh | v <- Vs, v in EsClosure[vd] || vd in EsClosure[v]);
    else if (vd notin Nsyn) // vd in Vt \ Vs
      Nsyn += (v:fresh | v <- Vt - Vs, nameAt(v, t) == Nt[vd]);
  };
  
  //println("Nsrc: <Nsrc>");
  //println("Nsyn: <Nsyn>");
  
  return <Nsrc,Nsyn>;
}

&T nameFix(type[&T<:node] astType, NameGraph Gs, &T t, NameGraph(&T) resolveT) 
  = x // vvvvv work around Rascal bug.
  when &T x := nameFix(Gs, t, rename, resolveT);

&T nameFix(NameGraph Gs, &T t, &T(&T t, map[ID,str] subst) rename, NameGraph(&T) resolveT) {
  Gt = resolveT(t);
  
  //println("Source edges: <Gs.E>");
  //println("Target edges: <Gt.E>");
  
  allBadBindings = badBindings(Gs, Gt); 
  if (allBadBindings == ()) return t;
  
  <Nsrc,Nsyn> = compRenamings(Gs, Gt, t, allBadBindings<1>);
  &T t_new = rename(t, Nsrc + Nsyn);
  
  return nameFix(Gs, t_new, rename, resolveT);
}