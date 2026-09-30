library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package AES_pkg is

    subtype byte_t is std_logic_vector(7 downto 0);
    type word_t is array(0 to 3) of byte_t;
    type state_t is array(0 to 3) of word_t;
    
    type sbox_t is array(0 to 255) of byte_t;

    function to_state(pt : std_logic_vector(127 downto 0)) return state_t;
    function from_state(s : state_t) return std_logic_vector;
    function sub_byte(val : byte_t) return byte_t;
    function sub_bytes(s : state_t) return state_t;
    function shift_rows(s : state_t) return state_t;
    function mix_columns(s : state_t) return state_t;
    function add_round_key(s : state_t; rk : state_t) return state_t;

end package AES_pkg;

package body AES_pkg is

    
    constant sbox : sbox_t := (
        -- sbox(row*16 + col) = S-box output for input byte 0x<row><col>
        -- col:     0      1      2      3      4      5      6      7      8      9      a      b      c      d      e      f
        x"63", x"7c", x"77", x"7b", x"f2", x"6b", x"6f", x"c5", x"30", x"01", x"67", x"2b", x"fe", x"d7", x"ab", x"76", -- row 0
        x"ca", x"82", x"c9", x"7d", x"fa", x"59", x"47", x"f0", x"ad", x"d4", x"a2", x"af", x"9c", x"a4", x"72", x"c0", -- row 1
        x"b7", x"fd", x"93", x"26", x"36", x"3f", x"f7", x"cc", x"34", x"a5", x"e5", x"f1", x"71", x"d8", x"31", x"15", -- row 2
        x"04", x"c7", x"23", x"c3", x"18", x"96", x"05", x"9a", x"07", x"12", x"80", x"e2", x"eb", x"27", x"b2", x"75", -- row 3
        x"09", x"83", x"2c", x"1a", x"1b", x"6e", x"5a", x"a0", x"52", x"3b", x"d6", x"b3", x"29", x"e3", x"2f", x"84", -- row 4
        x"53", x"d1", x"00", x"ed", x"20", x"fc", x"b1", x"5b", x"6a", x"cb", x"be", x"39", x"4a", x"4c", x"58", x"cf", -- row 5
        x"d0", x"ef", x"aa", x"fb", x"43", x"4d", x"33", x"85", x"45", x"f9", x"02", x"7f", x"50", x"3c", x"9f", x"a8", -- row 6
        x"51", x"a3", x"40", x"8f", x"92", x"9d", x"38", x"f5", x"bc", x"b6", x"da", x"21", x"10", x"ff", x"f3", x"d2", -- row 7
        x"cd", x"0c", x"13", x"ec", x"5f", x"97", x"44", x"17", x"c4", x"a7", x"7e", x"3d", x"64", x"5d", x"19", x"73", -- row 8
        x"60", x"81", x"4f", x"dc", x"22", x"2a", x"90", x"88", x"46", x"ee", x"b8", x"14", x"de", x"5e", x"0b", x"db", -- row 9
        x"e0", x"32", x"3a", x"0a", x"49", x"06", x"24", x"5c", x"c2", x"d3", x"ac", x"62", x"91", x"95", x"e4", x"79", -- row a
        x"e7", x"c8", x"37", x"6d", x"8d", x"d5", x"4e", x"a9", x"6c", x"56", x"f4", x"ea", x"65", x"7a", x"ae", x"08", -- row b
        x"ba", x"78", x"25", x"2e", x"1c", x"a6", x"b4", x"c6", x"e8", x"dd", x"74", x"1f", x"4b", x"bd", x"8b", x"8a", -- row c
        x"70", x"3e", x"b5", x"66", x"48", x"03", x"f6", x"0e", x"61", x"35", x"57", x"b9", x"86", x"c1", x"1d", x"9e", -- row d
        x"e1", x"f8", x"98", x"11", x"69", x"d9", x"8e", x"94", x"9b", x"1e", x"87", x"e9", x"ce", x"55", x"28", x"df", -- row e
        x"8c", x"a1", x"89", x"0d", x"bf", x"e6", x"42", x"68", x"41", x"99", x"2d", x"0f", x"b0", x"54", x"bb", x"16"  -- row f
    );

    function to_state(pt : std_logic_vector(127 downto 0)) return state_t is
        variable s : state_t;
    begin
        for c in 0 to 3 loop
            for r in 0 to 3 loop
                s(c)(r) := pt(127 - 8*(r + 4*c) downto 120 - 8*(r + 4*c));
            end loop;
        end loop;
        return s;
    end function;

    function from_state(s : state_t) return std_logic_vector is 
        variable pt : std_logic_vector(127 downto 0);
    begin  
        for c in 0 to 3 loop 
            for r in 0 to 3 loop
                pt(127 - 8*(r + 4*c) downto 120 - 8*(r + 4*c)) := s(c)(r);
            end loop;
        end loop;
        return pt;
    end function;

    function sub_byte(val : byte_t) return byte_t is
    begin
        return sbox(to_integer(unsigned(val)));
    end function;
 
    function sub_bytes(s : state_t) return state_t is    
        variable result : state_t;
    begin 
        for c in 0 to 3 loop
            for r in 0 to 3 loop
                result(c)(r) := sub_byte(s(c)(r));
            end loop;
        end loop;
        return result;
    end function;

    function shift_rows(s : state_t) return state_t is  
        variable result : state_t;
    begin 
        for c in 0 to 3 loop
            for r in 0 to 3 loop
                result(c)(r) := s((c + r) mod 4)(r);
            end loop;
        end loop;
        return result;
    end function;

    function xtime(b : byte_t) return byte_t is
        variable sh : byte_t;
    begin
        sh := b(6 downto 0) & '0';
        if b(7) = '1' then
            return sh xor x"1b";
        else
            return sh;
        end if;
    end function;

    function mix_columns(s : state_t) return state_t is 
        variable result : state_t;
    begin 
        for c in 0 to 3 loop 
            result(c)(0) := xtime(s(c)(0)) xor (xtime(s(c)(1)) xor s(c)(1)) xor s(c)(2) xor s(c)(3);
            result(c)(1) := s(c)(0) xor xtime(s(c)(1)) xor (xtime(s(c)(2)) xor s(c)(2)) xor s(c)(3);
            result(c)(2) := s(c)(0) xor s(c)(1) xor xtime(s(c)(2)) xor (xtime(s(c)(3)) xor s(c)(3));
            result(c)(3) := (xtime(s(c)(0)) xor s(c)(0)) xor s(c)(1) xor s(c)(2) xor xtime(s(c)(3));
        end loop;
        return result;
    end function;

    function add_round_key(s : state_t; rk : state_t) return state_t is
        variable result : state_t;
    begin
        for c in 0 to 3 loop
            for r in 0 to 3 loop
                result(c)(r) := s(c)(r) xor rk(c)(r);
            end loop;
        end loop;
        return result;
    end function;

end package body AES_pkg;
