library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity traffic_light_fsm is
    Port (
        clk  : in  STD_LOGIC;
        rst  : in  STD_LOGIC;
        tick : in  STD_LOGIC;
        sw   : in  STD_LOGIC_VECTOR(3 downto 0);  -- Input Switch SW3..SW0
        led  : out STD_LOGIC_VECTOR(5 downto 0)   -- Output 6 LED
    );
end traffic_light_fsm;

architecture Behavioral of traffic_light_fsm is

    -- Definisi 6 State
    type state_type is (NS_HIJAU, NS_KUNING, ALL_RED_1, EW_HIJAU, EW_KUNING, ALL_RED_2);
    signal current_state, next_state : state_type := NS_HIJAU;

    -- Signal Timer dan Perhitungan Durasi Hijau
    signal timer : integer range 0 to 20 := 5;
    signal green_duration : integer range 5 to 20 := 5;

begin

    -- Rumus Durasi Hijau: 5 + Nilai Desimal SW (5 s.d. 20 detik)
    green_duration <= 5 + to_integer(unsigned(sw));

    ------------------------------------------------------------------
    -- PROCESS 1: SINKRON / SEQUENTIAL (UPDATE STATE & TIMER)
    ------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                current_state <= NS_HIJAU;
                timer         <= green_duration;
            else
                -- Jika terjadi transisi state, muat ulang timer
                if current_state /= next_state then
                    current_state <= next_state;
                    case next_state is
                        when NS_HIJAU   => timer <= green_duration; -- 5..20 detik (Dinamis)
                        when NS_KUNING  => timer <= 3;               -- 3 detik
                        when ALL_RED_1  => timer <= 1;               -- 1 detik Jeda All-Red
                        when EW_HIJAU   => timer <= green_duration; -- 5..20 detik (Dinamis)
                        when EW_KUNING  => timer <= 3;               -- 3 detik
                        when ALL_RED_2  => timer <= 1;               -- 1 detik Jeda All-Red
                    end case;
                -- Jika timer berjalan, kurangi tiap pulsa tick=1
                elsif tick = '1' then
                    if timer > 0 then
                        timer <= timer - 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- PROCESS 2: KOMBINASIONAL (TRANSISI STATE)
    ------------------------------------------------------------------
    process(current_state, timer)
    begin
        next_state <= current_state;

        case current_state is
            when NS_HIJAU =>
                if timer = 0 then next_state <= NS_KUNING; end if;

            when NS_KUNING =>
                if timer = 0 then next_state <= ALL_RED_1; end if;

            when ALL_RED_1 =>
                if timer = 0 then next_state <= EW_HIJAU; end if;

            when EW_HIJAU =>
                if timer = 0 then next_state <= EW_KUNING; end if;

            when EW_KUNING =>
                if timer = 0 then next_state <= ALL_RED_2; end if;

            when ALL_RED_2 =>
                if timer = 0 then next_state <= NS_HIJAU; end if;
        end case;
    end process;

    ------------------------------------------------------------------
    -- PROCESS 3: DEKODE OUTPUT LED (SESUAI TABEL KEBENARAN)
    ------------------------------------------------------------------
    process(current_state)
    begin
        case current_state is
            when NS_HIJAU  => led <= "100001";
            when NS_KUNING => led <= "100010";
            when ALL_RED_1 => led <= "100100";
            when EW_HIJAU  => led <= "001100";
            when EW_KUNING => led <= "010100";
            when ALL_RED_2 => led <= "100100";
        end case;
    end process;

end Behavioral;