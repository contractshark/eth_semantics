(*Generated by Lem from word.lem.*)


open Lem_bool
open Lem_maybe
open Lem_num
open Lem_basic_classes
open Lem_list


(* ========================================================================== *)
(* Define general purpose word, i.e. sequences of bits of arbitrary length    *)
(* ========================================================================== *)

type bitSequence = BitSeq of 
    int option  * (* length of the sequence, Nothing means infinite length *)
   bool * bool       (* sign of the word, used to fill up after concrete value is exhausted *)
   list    (* the initial part of the sequence, least significant bit first *)

(*val bitSeqEq : bitSequence -> bitSequence -> bool*)
let instance_Basic_classes_Eq_Word_bitSequence_dict:(bitSequence)eq_class= ({

  isEqual_method = (=);

  isInequal_method = (fun n1 n2->not (n1 = n2))})

(*val boolListFrombitSeq : nat -> bitSequence -> list bool*)

let rec boolListFrombitSeqAux n s bl:'a list=  
 (if n = 0 then [] else
  (match bl with
    | []       -> replicate n s
    | b :: bl' -> b :: (boolListFrombitSeqAux (Nat_num.nat_monus n( 1)) s bl')
  ))

let boolListFrombitSeq n (BitSeq( _, s, bl)):(bool)list=  (boolListFrombitSeqAux n s bl)


(*val bitSeqFromBoolList : list bool -> maybe bitSequence*)
let bitSeqFromBoolList bl:(bitSequence)option=  
 ((match dest_init bl with
    | None -> None
    | Some (bl', s) -> Some (BitSeq( (Some (List.length bl)), s, bl'))
  ))


(* cleans up the representation of a bitSequence without changing its semantics *)
(*val cleanBitSeq : bitSequence -> bitSequence*)
let cleanBitSeq (BitSeq( len, s, bl)):bitSequence=  ((match len with
  | None -> (BitSeq( len, s, (List.rev (dropWhile ((=) s) (List.rev bl)))))
  | Some n  -> (BitSeq( len, s, (List.rev (dropWhile ((=) s) (List.rev (Lem_list.take (Nat_num.nat_monus n( 1)) bl))))))
))


(*val bitSeqTestBit : bitSequence -> nat -> maybe bool*)
let bitSeqTestBit (BitSeq( len, s, bl)) pos:(bool)option=  
  ((match len with
    | None -> if pos < List.length bl then list_index bl pos else Some s
    | Some l -> if (pos >= l) then None else
                if ((pos = ( Nat_num.nat_monus l( 1))) || (pos >= List.length bl)) then Some s else
                list_index bl pos
  ))

(*val bitSeqSetBit : bitSequence -> nat -> bool -> bitSequence*)
let bitSeqSetBit (BitSeq( len, s, bl)) pos v:bitSequence=  
 (let bl' = (if (pos < List.length bl) then bl else  List.rev_append (List.rev bl) (replicate pos s)) in
  let bl'' = (Lem_list.list_update bl' pos v) in
  let bs' = (BitSeq( len, s, bl'')) in
  cleanBitSeq bs')


(*val resizeBitSeq : maybe nat -> bitSequence -> bitSequence*)
let resizeBitSeq new_len bs:bitSequence=  
 (let (BitSeq( len, s, bl)) = (cleanBitSeq bs) in
  let shorten_opt = ((match (new_len, len) with
     | (None, _) -> None
     | (Some l1, None) -> Some l1
     | (Some l1, Some l2) -> if (l1 < l2) then Some l1 else None
  )) in
  (match shorten_opt with
    | None -> BitSeq( new_len, s, bl)
    | Some l1 -> (
        let bl' = (Lem_list.take l1 ( List.rev_append (List.rev bl) [s])) in
        (match dest_init bl' with
          | None -> (BitSeq( len, s, bl)) (* do nothing if size 0 is requested *)
          | Some (bl'', s') -> cleanBitSeq (BitSeq( new_len, s', bl''))
	))
  )) 

(*val bitSeqNot : bitSequence -> bitSequence*)
let bitSeqNot (BitSeq( len, s, bl)):bitSequence=  (BitSeq( len, (not s), (Lem_list.map not bl)))

(*val bitSeqBinop : (bool -> bool -> bool) -> bitSequence -> bitSequence -> bitSequence*)

(*val bitSeqBinopAux : (bool -> bool -> bool) -> bool -> list bool -> bool -> list bool -> list bool*)
let rec bitSeqBinopAux binop s1 bl1 s2 bl2:(bool)list=  
 ((match (bl1, bl2) with
    | ([], []) -> []
    | (b1 :: bl1', []) -> (binop b1 s2) :: bitSeqBinopAux binop s1 bl1' s2 []
    | ([], b2 :: bl2') -> (binop s1 b2) :: bitSeqBinopAux binop s1 []   s2 bl2'
    | (b1 :: bl1', b2 :: bl2') -> (binop b1 b2) :: bitSeqBinopAux binop s1 bl1' s2 bl2'
  ))

let bitSeqBinop binop bs1 bs2:bitSequence=  (
  let (BitSeq( len1, s1, bl1)) = (cleanBitSeq bs1) in
  let (BitSeq( len2, s2, bl2)) = (cleanBitSeq bs2) in

  let len = ((match (len1, len2) with
    | (Some l1, Some l2) -> Some (max l1 l2)
    | _ -> None
  )) in
  let s = (binop s1 s2) in
  let bl = (bitSeqBinopAux binop s1 bl1 s2 bl2) in
  cleanBitSeq (BitSeq( len, s, bl))
)

let bitSeqAnd:bitSequence ->bitSequence ->bitSequence=  (bitSeqBinop (&&))
let bitSeqOr:bitSequence ->bitSequence ->bitSequence=  (bitSeqBinop (||))
let bitSeqXor:bitSequence ->bitSequence ->bitSequence=  (bitSeqBinop (fun b1 b2->not (b1 = b2)))

(*val bitSeqShiftLeft : bitSequence -> nat -> bitSequence*)
let bitSeqShiftLeft (BitSeq( len, s, bl)) n:bitSequence=  (cleanBitSeq (BitSeq( len, s, ( List.rev_append (List.rev (replicate n false)) bl))))

(*val bitSeqArithmeticShiftRight : bitSequence -> nat -> bitSequence*)
let bitSeqArithmeticShiftRight bs n:bitSequence=  
  (let (BitSeq( len, s, bl)) = (cleanBitSeq bs) in
  cleanBitSeq (BitSeq( len, s, (drop n bl))))

(*val bitSeqLogicalShiftRight : bitSequence -> nat -> bitSequence*)
let bitSeqLogicalShiftRight bs n:bitSequence=  
  (if (n = 0) then cleanBitSeq bs else
  let (BitSeq( len, s, bl)) = (cleanBitSeq bs) in
  (match len with
    | None -> cleanBitSeq (BitSeq( len, s, (drop n bl)))
    | Some l -> cleanBitSeq (BitSeq( len, false, ( List.rev_append (List.rev (drop n bl)) (replicate l s))))
  ))


(* integerFromBoolList sign bl creates an integer from a list of bits
   (least significant bit first) and an explicitly given sign bit.
   It uses two's complement encoding. *)
(*val integerFromBoolList : (bool * list bool) -> integer*)

let rec integerFromBoolListAux (acc : Nat_big_num.num) (bl : bool list):Nat_big_num.num=  
  ((match bl with 
    | [] -> acc
    | (true :: bl') -> integerFromBoolListAux ( Nat_big_num.add( Nat_big_num.mul acc(Nat_big_num.of_int 2))(Nat_big_num.of_int 1)) bl'
    | (false :: bl') -> integerFromBoolListAux ( Nat_big_num.mul acc(Nat_big_num.of_int 2)) bl'
  ))

let integerFromBoolList (sign, bl):Nat_big_num.num=   
  (if sign then 
     Nat_big_num.negate( Nat_big_num.add(integerFromBoolListAux(Nat_big_num.of_int 0) (List.rev_map not bl))(Nat_big_num.of_int 1))
   else integerFromBoolListAux(Nat_big_num.of_int 0) (List.rev bl))

(* [boolListFromInteger i] creates a sign bit and a list of booleans from an integer. The len_opt tells it when to stop.*)
(*val boolListFromInteger :    integer -> bool * list bool*)

let rec boolListFromNatural acc (remainder : Nat_big_num.num):(bool)list= 
 (if ( Nat_big_num.greater remainder(Nat_big_num.of_int 0)) then 
   (boolListFromNatural (( Nat_big_num.equal( Nat_big_num.modulus remainder(Nat_big_num.of_int 2))(Nat_big_num.of_int 1)) :: acc) 
      ( Nat_big_num.div remainder(Nat_big_num.of_int 2)))
 else
   List.rev acc)

let boolListFromInteger (i : Nat_big_num.num):bool*(bool)list=  
  (if ( Nat_big_num.less i(Nat_big_num.of_int 0)) then
    (true, Lem_list.map not (boolListFromNatural [] (Nat_big_num.abs (Nat_big_num.negate( Nat_big_num.add i(Nat_big_num.of_int 1))))))
  else
    (false, boolListFromNatural [] (Nat_big_num.abs i)))


(* [bitSeqFromInteger len_opt i] encodes [i] as a bitsequence with [len_opt] bits. If there are not enough
   bits, truncation happens *)
(*val bitSeqFromInteger : maybe nat -> integer -> bitSequence*)
let bitSeqFromInteger len_opt i:bitSequence=  
 (let (s, bl) = (boolListFromInteger i) in
  resizeBitSeq len_opt (BitSeq( None, s, bl)))


(*val integerFromBitSeq : bitSequence -> integer*)
let integerFromBitSeq bs:Nat_big_num.num=  
 (let (BitSeq( len, s, bl)) = (cleanBitSeq bs) in
  integerFromBoolList (s, bl))


(* Now we can via translation to integers map arithmetic operations to bitSequences *)

(*val bitSeqArithUnaryOp : (integer -> integer) -> bitSequence -> bitSequence*)
let bitSeqArithUnaryOp uop bs:bitSequence=  
 (let (BitSeq( len, _, _)) = bs in
  bitSeqFromInteger len (uop (integerFromBitSeq bs)))

(*val bitSeqArithBinOp : (integer -> integer -> integer) -> bitSequence -> bitSequence -> bitSequence*)
let bitSeqArithBinOp binop bs1 bs2:bitSequence=  
 (let (BitSeq( len1, _, _)) = bs1 in
  let (BitSeq( len2, _, _)) = bs2 in
  let len = ((match (len1, len2) with 
    | (Some l1, Some l2) -> Some (max l1 l2)
    | _ -> None
  )) in
  bitSeqFromInteger len (binop (integerFromBitSeq bs1) (integerFromBitSeq bs2)))

(*val bitSeqArithBinTest : forall 'a. (integer -> integer -> 'a) -> bitSequence -> bitSequence -> 'a*)
let bitSeqArithBinTest binop bs1 bs2:'a=  (binop (integerFromBitSeq bs1) (integerFromBitSeq bs2))


(* now instantiate the number interface for bit-sequences *)

(*val bitSeqFromNumeral : numeral -> bitSequence*)

(*val bitSeqLess : bitSequence -> bitSequence -> bool*)
let bitSeqLess bs1 bs2:bool=  (bitSeqArithBinTest Nat_big_num.less bs1 bs2)

(*val bitSeqLessEqual : bitSequence -> bitSequence -> bool*)
let bitSeqLessEqual bs1 bs2:bool=  (bitSeqArithBinTest Nat_big_num.less_equal bs1 bs2)

(*val bitSeqGreater : bitSequence -> bitSequence -> bool*)
let bitSeqGreater bs1 bs2:bool=  (bitSeqArithBinTest Nat_big_num.greater bs1 bs2)

(*val bitSeqGreaterEqual : bitSequence -> bitSequence -> bool*)
let bitSeqGreaterEqual bs1 bs2:bool=  (bitSeqArithBinTest Nat_big_num.greater_equal bs1 bs2)

(*val bitSeqCompare : bitSequence -> bitSequence -> ordering*)
let bitSeqCompare bs1 bs2:int=  (bitSeqArithBinTest Nat_big_num.compare bs1 bs2)

let instance_Basic_classes_Ord_Word_bitSequence_dict:(bitSequence)ord_class= ({

  compare_method = bitSeqCompare;

  isLess_method = bitSeqLess;

  isLessEqual_method = bitSeqLessEqual;

  isGreater_method = bitSeqGreater;

  isGreaterEqual_method = bitSeqGreaterEqual})

let instance_Basic_classes_SetType_Word_bitSequence_dict:(bitSequence)setType_class= ({

  setElemCompare_method = bitSeqCompare})

(* arithmetic negation, don't mix up with bitwise negation *)
(*val bitSeqNegate : bitSequence -> bitSequence*) 
let bitSeqNegate bs:bitSequence=  (bitSeqArithUnaryOp Nat_big_num.negate bs)

let instance_Num_NumNegate_Word_bitSequence_dict:(bitSequence)numNegate_class= ({

  numNegate_method = bitSeqNegate})


(*val bitSeqAdd : bitSequence -> bitSequence -> bitSequence*)
let bitSeqAdd bs1 bs2:bitSequence=  (bitSeqArithBinOp Nat_big_num.add bs1 bs2)

let instance_Num_NumAdd_Word_bitSequence_dict:(bitSequence)numAdd_class= ({

  numAdd_method = bitSeqAdd})

(*val bitSeqMinus : bitSequence -> bitSequence -> bitSequence*)
let bitSeqMinus bs1 bs2:bitSequence=  (bitSeqArithBinOp Nat_big_num.sub bs1 bs2)

let instance_Num_NumMinus_Word_bitSequence_dict:(bitSequence)numMinus_class= ({

  numMinus_method = bitSeqMinus})

(*val bitSeqSucc : bitSequence -> bitSequence*)
let bitSeqSucc bs:bitSequence=  (bitSeqArithUnaryOp Nat_big_num.succ bs)

let instance_Num_NumSucc_Word_bitSequence_dict:(bitSequence)numSucc_class= ({

  succ_method = bitSeqSucc})

(*val bitSeqPred : bitSequence -> bitSequence*)
let bitSeqPred bs:bitSequence=  (bitSeqArithUnaryOp Nat_big_num.pred bs)

let instance_Num_NumPred_Word_bitSequence_dict:(bitSequence)numPred_class= ({

  pred_method = bitSeqPred})

(*val bitSeqMult : bitSequence -> bitSequence -> bitSequence*)
let bitSeqMult bs1 bs2:bitSequence=  (bitSeqArithBinOp Nat_big_num.mul bs1 bs2)

let instance_Num_NumMult_Word_bitSequence_dict:(bitSequence)numMult_class= ({

  numMult_method = bitSeqMult})


(*val bitSeqPow : bitSequence -> nat -> bitSequence*)
let bitSeqPow bs n:bitSequence=  (bitSeqArithUnaryOp (fun i -> Nat_big_num.pow_int i n) bs)

let instance_Num_NumPow_Word_bitSequence_dict:(bitSequence)numPow_class= ({

  numPow_method = bitSeqPow})

(*val bitSeqDiv : bitSequence -> bitSequence -> bitSequence*)
let bitSeqDiv bs1 bs2:bitSequence=  (bitSeqArithBinOp Nat_big_num.div bs1 bs2)

let instance_Num_NumIntegerDivision_Word_bitSequence_dict:(bitSequence)numIntegerDivision_class= ({

  div_method = bitSeqDiv})

let instance_Num_NumDivision_Word_bitSequence_dict:(bitSequence)numDivision_class= ({

  numDivision_method = bitSeqDiv})

(*val bitSeqMod : bitSequence -> bitSequence -> bitSequence*)
let bitSeqMod bs1 bs2:bitSequence=  (bitSeqArithBinOp Nat_big_num.modulus bs1 bs2)

let instance_Num_NumRemainder_Word_bitSequence_dict:(bitSequence)numRemainder_class= ({

  mod_method = bitSeqMod})

(*val bitSeqMin : bitSequence -> bitSequence -> bitSequence*)
let bitSeqMin bs1 bs2:bitSequence=  (bitSeqArithBinOp Nat_big_num.min bs1 bs2)

(*val bitSeqMax : bitSequence -> bitSequence -> bitSequence*)
let bitSeqMax bs1 bs2:bitSequence=  (bitSeqArithBinOp Nat_big_num.max bs1 bs2)

let instance_Basic_classes_OrdMaxMin_Word_bitSequence_dict:(bitSequence)ordMaxMin_class= ({

  max_method = bitSeqMax;

  min_method = bitSeqMin})




(* ========================================================================== *)
(* Interface for bitoperations                                                *)
(* ========================================================================== *)

type 'a wordNot_class= {
  lnot_method : 'a -> 'a
}

type 'a wordAnd_class= {
  land_method  : 'a -> 'a -> 'a
}

type 'a wordOr_class= {
  lor_method : 'a -> 'a -> 'a
}


type 'a wordXor_class= {
  lxor_method : 'a -> 'a -> 'a
}

type 'a wordLsl_class= {
  lsl_method : 'a -> int -> 'a
}

type 'a wordLsr_class= {
  lsr_method : 'a -> int -> 'a
}

type 'a wordAsr_class= {
  asr_method : 'a -> int -> 'a
}

(* ----------------------- *)
(* bitSequence             *)
(* ----------------------- *)

let instance_Word_WordNot_Word_bitSequence_dict:(bitSequence)wordNot_class= ({

  lnot_method = bitSeqNot})

let instance_Word_WordAnd_Word_bitSequence_dict:(bitSequence)wordAnd_class= ({

  land_method = bitSeqAnd})

let instance_Word_WordOr_Word_bitSequence_dict:(bitSequence)wordOr_class= ({

  lor_method = bitSeqOr})

let instance_Word_WordXor_Word_bitSequence_dict:(bitSequence)wordXor_class= ({

  lxor_method = bitSeqXor})

let instance_Word_WordLsl_Word_bitSequence_dict:(bitSequence)wordLsl_class= ({

  lsl_method = bitSeqShiftLeft})

let instance_Word_WordLsr_Word_bitSequence_dict:(bitSequence)wordLsr_class= ({

  lsr_method = bitSeqLogicalShiftRight})

let instance_Word_WordAsr_Word_bitSequence_dict:(bitSequence)wordAsr_class= ({

  asr_method = bitSeqArithmeticShiftRight})


(* ----------------------- *)
(* int32                   *)
(* ----------------------- *)

(*val int32Lnot : int32 -> int32*) (* XXX: fix *)

let instance_Word_WordNot_Num_int32_dict:(Int32.t)wordNot_class= ({

  lnot_method = Int32.lognot})


(*val int32Lor  : int32 -> int32 -> int32*) (* XXX: fix *)

let instance_Word_WordOr_Num_int32_dict:(Int32.t)wordOr_class= ({

  lor_method = Int32.logor})

(*val int32Lxor : int32 -> int32 -> int32*) (* XXX: fix *)

let instance_Word_WordXor_Num_int32_dict:(Int32.t)wordXor_class= ({

  lxor_method = Int32.logxor})

(*val int32Land : int32 -> int32 -> int32*) (* XXX: fix *)

let instance_Word_WordAnd_Num_int32_dict:(Int32.t)wordAnd_class= ({

  land_method = Int32.logand})

(*val int32Lsl  : int32 -> nat -> int32*) (* XXX: fix *)

let instance_Word_WordLsl_Num_int32_dict:(Int32.t)wordLsl_class= ({

  lsl_method = Int32.shift_left})

(*val int32Lsr  : int32 -> nat -> int32*) (* XXX: fix *)

let instance_Word_WordLsr_Num_int32_dict:(Int32.t)wordLsr_class= ({

  lsr_method = Int32.shift_right_logical})


(*val int32Asr  : int32 -> nat -> int32*) (* XXX: fix *)

let instance_Word_WordAsr_Num_int32_dict:(Int32.t)wordAsr_class= ({

  asr_method = Int32.shift_right})


(* ----------------------- *)
(* int64                   *)
(* ----------------------- *)

(*val int64Lnot : int64 -> int64*) (* XXX: fix *)

let instance_Word_WordNot_Num_int64_dict:(Int64.t)wordNot_class= ({

  lnot_method = Int64.lognot})

(*val int64Lor  : int64 -> int64 -> int64*) (* XXX: fix *)

let instance_Word_WordOr_Num_int64_dict:(Int64.t)wordOr_class= ({

  lor_method = Int64.logor})

(*val int64Lxor : int64 -> int64 -> int64*) (* XXX: fix *)

let instance_Word_WordXor_Num_int64_dict:(Int64.t)wordXor_class= ({

  lxor_method = Int64.logxor})

(*val int64Land : int64 -> int64 -> int64*) (* XXX: fix *)

let instance_Word_WordAnd_Num_int64_dict:(Int64.t)wordAnd_class= ({

  land_method = Int64.logand})

(*val int64Lsl  : int64 -> nat -> int64*) (* XXX: fix *)

let instance_Word_WordLsl_Num_int64_dict:(Int64.t)wordLsl_class= ({

  lsl_method = Int64.shift_left})

(*val int64Lsr  : int64 -> nat -> int64*) (* XXX: fix *)

let instance_Word_WordLsr_Num_int64_dict:(Int64.t)wordLsr_class= ({

  lsr_method = Int64.shift_right_logical})

(*val int64Asr  : int64 -> nat -> int64*) (* XXX: fix *)

let instance_Word_WordAsr_Num_int64_dict:(Int64.t)wordAsr_class= ({

  asr_method = Int64.shift_right})


(* ----------------------- *)
(* Words via bit sequences *)
(* ----------------------- *)

(*val defaultLnot : forall 'a. (bitSequence -> 'a) -> ('a -> bitSequence) -> 'a -> 'a*) 
let defaultLnot fromBitSeq toBitSeq x:'a=  (fromBitSeq (bitSeqNegate (toBitSeq x)))

(*val defaultLand : forall 'a. (bitSequence -> 'a) -> ('a -> bitSequence) -> 'a -> 'a -> 'a*)
let defaultLand fromBitSeq toBitSeq x1 x2:'a=  (fromBitSeq (bitSeqAnd (toBitSeq x1) (toBitSeq x2)))

(*val defaultLor : forall 'a. (bitSequence -> 'a) -> ('a -> bitSequence) -> 'a -> 'a -> 'a*)
let defaultLor fromBitSeq toBitSeq x1 x2:'a=  (fromBitSeq (bitSeqOr (toBitSeq x1) (toBitSeq x2)))

(*val defaultLxor : forall 'a. (bitSequence -> 'a) -> ('a -> bitSequence) -> 'a -> 'a -> 'a*)
let defaultLxor fromBitSeq toBitSeq x1 x2:'a=  (fromBitSeq (bitSeqXor (toBitSeq x1) (toBitSeq x2)))

(*val defaultLsl : forall 'a. (bitSequence -> 'a) -> ('a -> bitSequence) -> 'a -> nat -> 'a*)
let defaultLsl fromBitSeq toBitSeq x n:'a=  (fromBitSeq (bitSeqShiftLeft (toBitSeq x) n))

(*val defaultLsr : forall 'a. (bitSequence -> 'a) -> ('a -> bitSequence) -> 'a -> nat -> 'a*)
let defaultLsr fromBitSeq toBitSeq x n:'a=  (fromBitSeq (bitSeqLogicalShiftRight (toBitSeq x) n))

(*val defaultAsr : forall 'a. (bitSequence -> 'a) -> ('a -> bitSequence) -> 'a -> nat -> 'a*)
let defaultAsr fromBitSeq toBitSeq x n:'a=  (fromBitSeq (bitSeqArithmeticShiftRight (toBitSeq x) n))

(* ----------------------- *)
(* integer                 *)
(* ----------------------- *)

(*val integerLnot : integer -> integer*)
let integerLnot i:Nat_big_num.num=  (Nat_big_num.negate( Nat_big_num.add i(Nat_big_num.of_int 1)))

let instance_Word_WordNot_Num_integer_dict:(Nat_big_num.num)wordNot_class= ({

  lnot_method = integerLnot})


(*val integerLor  : integer -> integer -> integer*)
(*let integerLor i1 i2:integer=  defaultLor integerFromBitSeq (bitSeqFromInteger Nothing) i1 i2*)

let instance_Word_WordOr_Num_integer_dict:(Nat_big_num.num)wordOr_class= ({

  lor_method = Nat_big_num.bitwise_or})

(*val integerLxor : integer -> integer -> integer*)
(*let integerLxor i1 i2:integer=  defaultLxor integerFromBitSeq (bitSeqFromInteger Nothing) i1 i2*)

let instance_Word_WordXor_Num_integer_dict:(Nat_big_num.num)wordXor_class= ({

  lxor_method = Nat_big_num.bitwise_xor})

(*val integerLand : integer -> integer -> integer*)
(*let integerLand i1 i2:integer=  defaultLand integerFromBitSeq (bitSeqFromInteger Nothing) i1 i2*)

let instance_Word_WordAnd_Num_integer_dict:(Nat_big_num.num)wordAnd_class= ({

  land_method = Nat_big_num.bitwise_and})

(*val integerLsl  : integer -> nat -> integer*)
(*let integerLsl i n:integer=  defaultLsl integerFromBitSeq (bitSeqFromInteger Nothing) i n*)

let instance_Word_WordLsl_Num_integer_dict:(Nat_big_num.num)wordLsl_class= ({

  lsl_method = Nat_big_num.shift_left})

(*val integerAsr  : integer -> nat -> integer*)
(*let integerAsr i n:integer=  defaultAsr integerFromBitSeq (bitSeqFromInteger Nothing) i n*)

let instance_Word_WordLsr_Num_integer_dict:(Nat_big_num.num)wordLsr_class= ({

  lsr_method = Nat_big_num.shift_right})

let instance_Word_WordAsr_Num_integer_dict:(Nat_big_num.num)wordAsr_class= ({

  asr_method = Nat_big_num.shift_right})


(* ----------------------- *)
(* int                     *)
(* ----------------------- *)

(* sometimes it is convenient to be able to perform bit-operations on ints.
   However, since int is not well-defined (it has different size on different systems),
   it should be used very carefully and only for operations that don't depend on the
   bitwidth of int *)

(*val intFromBitSeq : bitSequence -> int*)
let intFromBitSeq bs:int=  (Nat_big_num.to_int (integerFromBitSeq (resizeBitSeq (Some( 31)) bs)))


(*val bitSeqFromInt : int -> bitSequence*) 
let bitSeqFromInt i:bitSequence=  (bitSeqFromInteger (Some( 31)) (Nat_big_num.of_int i))


(*val intLnot : int -> int*)
(*let intLnot i:int=  Instance_Num_NumNegate_Num_int.~((Instance_Num_NumAdd_Num_int.+) i 1)*)

let instance_Word_WordNot_Num_int_dict:(int)wordNot_class= ({

  lnot_method = lnot})

(*val intLor  : int -> int -> int*)
(*let intLor i1 i2:int=  defaultLor intFromBitSeq bitSeqFromInt i1 i2*)

let instance_Word_WordOr_Num_int_dict:(int)wordOr_class= ({

  lor_method = (lor)})

(*val intLxor : int -> int -> int*)
(*let intLxor i1 i2:int=  defaultLxor intFromBitSeq bitSeqFromInt i1 i2*)

let instance_Word_WordXor_Num_int_dict:(int)wordXor_class= ({

  lxor_method = (lxor)})

(*val intLand : int -> int -> int*)
(*let intLand i1 i2:int=  defaultLand intFromBitSeq bitSeqFromInt i1 i2*)

let instance_Word_WordAnd_Num_int_dict:(int)wordAnd_class= ({

  land_method = (land)})

(*val intLsl  : int -> nat -> int*)
(*let intLsl i n:int=  defaultLsl intFromBitSeq bitSeqFromInt i n*)

let instance_Word_WordLsl_Num_int_dict:(int)wordLsl_class= ({

  lsl_method = (lsl)})

(*val intAsr  : int -> nat -> int*)
(*let intAsr i n:int=  defaultAsr intFromBitSeq bitSeqFromInt i n*)

let instance_Word_WordAsr_Num_int_dict:(int)wordAsr_class= ({

  asr_method = (asr)})



(* ----------------------- *)
(* natural                 *)
(* ----------------------- *)

(* some operations work also on positive numbers *)

(*val naturalFromBitSeq : bitSequence -> natural*)
let naturalFromBitSeq bs:Nat_big_num.num=
  (Nat_big_num.abs (integerFromBitSeq bs))

(*val bitSeqFromNatural : maybe nat -> natural -> bitSequence*)
let bitSeqFromNatural len n:bitSequence=  (bitSeqFromInteger len ( n))

(*val naturalLor  : natural -> natural -> natural*)
(*let naturalLor i1 i2:natural=  defaultLor naturalFromBitSeq (bitSeqFromNatural Nothing) i1 i2*)

let instance_Word_WordOr_Num_natural_dict:(Nat_big_num.num)wordOr_class= ({

  lor_method = Nat_big_num.bitwise_or})

(*val naturalLxor : natural -> natural -> natural*)
(*let naturalLxor i1 i2:natural=  defaultLxor naturalFromBitSeq (bitSeqFromNatural Nothing) i1 i2*)

let instance_Word_WordXor_Num_natural_dict:(Nat_big_num.num)wordXor_class= ({

  lxor_method = Nat_big_num.bitwise_xor})

(*val naturalLand : natural -> natural -> natural*)
(*let naturalLand i1 i2:natural=  defaultLand naturalFromBitSeq (bitSeqFromNatural Nothing) i1 i2*)

let instance_Word_WordAnd_Num_natural_dict:(Nat_big_num.num)wordAnd_class= ({

  land_method = Nat_big_num.bitwise_and})

(*val naturalLsl  : natural -> nat -> natural*)
(*let naturalLsl i n:natural=  defaultLsl naturalFromBitSeq (bitSeqFromNatural Nothing) i n*)

let instance_Word_WordLsl_Num_natural_dict:(Nat_big_num.num)wordLsl_class= ({

  lsl_method = Nat_big_num.shift_left})

(*val naturalAsr  : natural -> nat -> natural*)
(*let naturalAsr i n:natural=  defaultAsr naturalFromBitSeq (bitSeqFromNatural Nothing) i n*)

let instance_Word_WordLsr_Num_natural_dict:(Nat_big_num.num)wordLsr_class= ({

  lsr_method = Nat_big_num.shift_right})

let instance_Word_WordAsr_Num_natural_dict:(Nat_big_num.num)wordAsr_class= ({

  asr_method = Nat_big_num.shift_right})


(* ----------------------- *)
(* nat                     *)
(* ----------------------- *)

(* sometimes it is convenient to be able to perform bit-operations on nats.
   However, since nat is not well-defined (it has different size on different systems),
   it should be used very carefully and only for operations that don't depend on the
   bitwidth of nat *)

(*val natFromBitSeq : bitSequence -> nat*)
let natFromBitSeq bs:int=  (Nat_big_num.to_int (naturalFromBitSeq (resizeBitSeq (Some( 31)) bs)))


(*val bitSeqFromNat : nat -> bitSequence*) 
let bitSeqFromNat i:bitSequence=  (bitSeqFromNatural (Some( 31)) (Nat_big_num.of_int i))


(*val natLor  : nat -> nat -> nat*)
(*let natLor i1 i2:nat=  defaultLor natFromBitSeq bitSeqFromNat i1 i2*)

let instance_Word_WordOr_nat_dict:(int)wordOr_class= ({

  lor_method = (lor)})

(*val natLxor : nat -> nat -> nat*)
(*let natLxor i1 i2:nat=  defaultLxor natFromBitSeq bitSeqFromNat i1 i2*)

let instance_Word_WordXor_nat_dict:(int)wordXor_class= ({

  lxor_method = (lxor)})

(*val natLand : nat -> nat -> nat*)
(*let natLand i1 i2:nat=  defaultLand natFromBitSeq bitSeqFromNat i1 i2*)

let instance_Word_WordAnd_nat_dict:(int)wordAnd_class= ({

  land_method = (land)})

(*val natLsl  : nat -> nat -> nat*)
(*let natLsl i n:nat=  defaultLsl natFromBitSeq bitSeqFromNat i n*)

let instance_Word_WordLsl_nat_dict:(int)wordLsl_class= ({

  lsl_method = (lsl)})

(*val natAsr  : nat -> nat -> nat*)
(*let natAsr i n:nat=  defaultAsr natFromBitSeq bitSeqFromNat i n*)

let instance_Word_WordAsr_nat_dict:(int)wordAsr_class= ({

  asr_method = (asr)})
